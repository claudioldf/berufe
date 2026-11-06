# frozen_string_literal: true

require "digest"
require "json"
require "net/http"
require "timeout"
require "uri"

module SearchResolvers
  # Interprets a search expression with JEV (TypeSafe System One). JEV does not
  # generate text: it answers typed questions about the expression with
  # probabilities, which are mapped onto the same payload the LLM resolver
  # returns. Keywords stay empty and the contact sentence is templated.
  class Jev
    ENDPOINT = "https://api.typesafe.ai/v1/systemone"
    DEFAULT_RETRY_AFTER = 60
    MAXIMUM_RETRY_AFTER = 1.hour.to_i
    MAXIMUM_SERVICES = 5
    # JEV rejects a choice question with more than 255 options (HTTP 422).
    MAXIMUM_CHOICE_OPTIONS = 255
    MAXIMUM_CITY_CANDIDATES = 20
    OTHER_CITY = "outra_cidade"
    NO_NEIGHBORHOOD = "nenhum"
    # City name that can never match a supported city, so the parser rejects
    # the search exactly as it does when an LLM names an unsupported city.
    UNSUPPORTED_CITY = "cidade não suportada"

    attr_reader :adapter, :model

    def initialize(
      api_key:,
      model:,
      timeout_seconds:,
      min_confidence:,
      secondary_probability:,
      endpoint: ENDPOINT,
      http: Net::HTTP
    )
      @adapter = "jev"
      @api_key = api_key
      @model = model
      @timeout_seconds = timeout_seconds.to_f
      @min_confidence = min_confidence
      @secondary_probability = secondary_probability
      @endpoint = URI.parse(endpoint)
      @http = http
    end

    def call(expression:, services:, neighborhoods:, default_location:)
      started_at = Process.clock_gettime(Process::CLOCK_MONOTONIC)
      questions = questions_for(expression:, services:, neighborhoods:, default_location:)
      bodies = [post(state: expression, questions:)]
      body = bodies.first
      selected_location = selected_location(body, default_location:)
      neighborhood = nil

      if selected_location == :unsupported
        locations = [{"state_code" => nil, "city" => UNSUPPORTED_CITY, "neighborhood" => nil}]
        city = nil
      elsif selected_location.city_code == default_location.city_code
        city = selected_location
        neighborhood = neighborhood_from(body, neighborhoods:)
      else
        city = selected_location
        city_neighborhoods = Neighborhood.where(city_code: city.city_code).ordered.to_a
        question = neighborhood_question(city_neighborhoods, city_name: city.city, expression:)
        if question
          follow_up = post(state: expression, questions: {"neighborhood" => question})
          bodies << follow_up
          neighborhood = neighborhood_from(follow_up, neighborhoods: city_neighborhoods)
        end
      end

      matched_services = matched_services(body, services:)
      locations ||= [{
        "state_code" => city.state_code,
        "city" => city.city,
        "neighborhood" => neighborhood&.name
      }]
      payload = {
        "service_ids" => matched_services.map(&:id),
        "locations" => locations,
        "keywords" => [],
        "normalized_request" => normalized_request(matched_services.first, neighborhood:, city:)
      }

      ::Llm::Client::Response.new(
        payload:,
        raw_response: JSON.generate(bodies),
        provider_request_id: nil,
        input_tokens: bodies.sum { |entry| entry.dig("usage", "input_tokens").to_i },
        cached_input_tokens: nil,
        output_tokens: bodies.sum { |entry| entry.dig("usage", "output_tokens").to_i },
        latency_ms: elapsed_milliseconds(started_at)
      )
    end

    def prompt_digest(services:, neighborhoods:, default_location:)
      # The questions depend on the expression (city and neighborhood
      # shortlists), which the cache key already includes, so the digest
      # fingerprints the catalogs the questions are built from instead.
      Digest::SHA256.hexdigest(
        JSON.generate(
          services: service_criteria(services),
          neighborhoods: neighborhoods.map { |neighborhood| [neighborhood.code, neighborhood.name] },
          cities: supported_locations.map { |location| [location.city_code, location.city, location.state_code] },
          default_city_code: default_location.city_code,
          limits: [MAXIMUM_CHOICE_OPTIONS, MAXIMUM_CITY_CANDIDATES],
          min_confidence:,
          secondary_probability:
        )
      )
    end

    private

    attr_reader :api_key, :timeout_seconds, :min_confidence, :secondary_probability, :endpoint, :http

    def questions_for(expression:, services:, neighborhoods:, default_location:)
      questions = {}
      if services.any?
        questions["wants_service"] = {
          "type" => "noul",
          "instructions" => "O texto descreve um serviço ou o tipo de profissional que a pessoa quer contratar?"
        }
        questions["service"] = {
          "type" => "choice",
          "instructions" => "Qual serviço do catálogo melhor atende ao pedido?",
          "criteria" => service_criteria(services)
        }
      end
      questions["mentions_city"] = {
        "type" => "noul",
        "instructions" => "O texto cita explicitamente o nome de uma cidade? Bairros e regiões dentro da cidade não contam."
      }
      questions["city"] = {
        "type" => "choice",
        "instructions" => "Qual cidade o texto cita?",
        "criteria" => city_options(expression, default_location)
      }
      neighborhood = neighborhood_question(neighborhoods, city_name: default_location.city, expression:)
      questions["neighborhood"] = neighborhood if neighborhood
      questions
    end

    def service_criteria(services)
      services.to_h do |service|
        [service.slug, {"nome" => service.name, "aliases" => service.aliases, "descricao" => service.description}]
      end
    end

    # Every supported city would exceed JEV's option limit, so only the default
    # city and the cities whose name appears in the text are offered. A city
    # the text names that is not among them can only be "outra_cidade".
    def city_options(expression, default_location)
      options = {default_location.city_code => "#{default_location.city}/#{default_location.state_code}"}
      city_candidates(expression).each do |location|
        options[location.city_code] ||= "#{location.city}/#{location.state_code}"
      end
      options.merge(OTHER_CITY => "Uma cidade que não está na lista")
    end

    def city_candidates(expression)
      haystack = " #{PublicSearchText.normalize(expression)} "
      matches = supported_locations.filter_map do |location|
        name = PublicSearchText.normalize(location.city)
        [location, name] if name.present? && haystack.include?(" #{name} ")
      end
      # "Rio de Janeiro" in the text must not also offer a city named "Rio".
      matches
        .reject { |_, name| matches.any? { |_, other| other != name && " #{other} ".include?(" #{name} ") } }
        .sort_by { |location, name| [-name.length, location.state_code, location.city] }
        .first(MAXIMUM_CITY_CANDIDATES)
        .map(&:first)
    end

    # nil when there is nothing to ask: no neighborhoods, or a list too long
    # for JEV where no neighborhood name appears in the text.
    def neighborhood_question(neighborhoods, city_name:, expression:)
      options = neighborhood_options(neighborhoods, expression)
      return if options.empty?

      {
        "type" => "choice",
        "instructions" => "Qual bairro de #{city_name} o texto cita?",
        "criteria" => options.to_h { |neighborhood| [neighborhood.code, neighborhood.name] }
          .merge(NO_NEIGHBORHOOD => "Nenhum bairro é citado")
      }
    end

    def neighborhood_options(neighborhoods, expression)
      return neighborhoods if neighborhoods.size < MAXIMUM_CHOICE_OPTIONS

      haystack = " #{PublicSearchText.normalize(expression)} "
      neighborhoods
        .select { |neighborhood| haystack.include?(" #{PublicSearchText.normalize(neighborhood.name)} ") }
        .sort_by { |neighborhood| -neighborhood.name.length }
        .first(MAXIMUM_CHOICE_OPTIONS - 1)
    end

    def supported_locations
      @supported_locations ||= SupportedSearchLocations.new.all
    end

    def matched_services(body, services:)
      return [] unless body["answers"].key?("wants_service")
      return [] unless answer(body, "wants_service", "noul").fetch("noul") >= min_confidence

      choice = answer(body, "service", "choice")
      return [] unless choice.fetch("confidence") >= min_confidence

      services_by_slug = services.index_by(&:slug)
      choice.fetch("probabilities")
        .select { |slug, probability| slug == choice["choice"] || probability >= secondary_probability }
        .sort_by { |slug, probability| [(slug == choice["choice"]) ? 0 : 1, -probability] }
        .filter_map { |slug, _probability| services_by_slug[slug] }
        .first(MAXIMUM_SERVICES)
    end

    def selected_location(body, default_location:)
      return default_location unless mentions_city?(body)

      choice = answer(body, "city", "choice")
      return default_location if choice.fetch("confidence") < min_confidence
      return :unsupported if choice["choice"] == OTHER_CITY

      supported_locations.find { |location| location.city_code == choice["choice"] } || default_location
    end

    def mentions_city?(body)
      answer(body, "mentions_city", "noul").fetch("noul") >= min_confidence
    end

    def neighborhood_from(body, neighborhoods:)
      return unless body["answers"].key?("neighborhood")

      choice = answer(body, "neighborhood", "choice")
      return if choice["choice"] == NO_NEIGHBORHOOD || choice.fetch("confidence") < min_confidence

      neighborhoods.find { |neighborhood| neighborhood.code == choice["choice"] }
    end

    def normalized_request(service, neighborhood:, city:)
      return unless service && city

      SearchNormalizedRequest.call(
        service_name: service.name,
        location_name: neighborhood&.name || city.city,
        state_code: city.state_code
      )
    end

    def answer(body, id, type)
      value = body.dig("answers", id)
      unless value.is_a?(Hash) && value["type"] == type && valid_answer?(value, type)
        raise ::Llm::Client::InvalidResponse.new(raw_response: JSON.generate(body))
      end

      value
    end

    def valid_answer?(value, type)
      if type == "noul"
        value["noul"].is_a?(Numeric)
      else
        value["choice"].is_a?(String) &&
          value["confidence"].is_a?(Numeric) &&
          value["probabilities"].is_a?(Hash) &&
          value["probabilities"].values.all? { |probability| probability.is_a?(Numeric) && probability.between?(0, 1) }
      end
    end

    def post(state:, questions:)
      request = Net::HTTP::Post.new(endpoint)
      request["Authorization"] = "Bearer #{api_key}"
      request["Accept"] = "application/json"
      request["Content-Type"] = "application/json"
      request.body = JSON.generate(model:, state:, questions:)

      response = http.start(
        endpoint.host,
        endpoint.port,
        use_ssl: endpoint.scheme == "https",
        open_timeout: timeout_seconds,
        read_timeout: timeout_seconds
      ) { |connection| connection.request(request) }
      body = parse(response)
      questions.each { |id, question| answer(body, id, question.fetch("type")) }
      body
    rescue IOError, SocketError, SystemCallError, Timeout::Error => error
      Rails.error.report(error)
      raise ::Llm::Client::Unavailable, "JEV request failed"
    end

    def parse(response)
      status = response.code.to_i
      raise ::Llm::Client::RateLimited.new(retry_after: retry_after(response)) if [429, 529].include?(status)
      raise ::Llm::Client::Unavailable, "JEV returned HTTP #{status}#{validation_detail(response, status)}" unless status.between?(200, 299)

      body = JSON.parse(response.body)
      unless body.is_a?(Hash) && body["answers"].is_a?(Hash)
        raise ::Llm::Client::InvalidResponse.new(raw_response: response.body.to_s)
      end

      body
    rescue JSON::ParserError
      raise ::Llm::Client::InvalidResponse.new(raw_response: response.body.to_s)
    end

    # Names which request field JEV rejected (e.g. "questions.city.criteria,
    # too_long"). Only `loc` and `type` are used: `input` and `msg` can echo
    # the user's text, which must not reach error reports.
    def validation_detail(response, status)
      return "" unless status == 422

      body = JSON.parse(response.body)
      return "" unless body.is_a?(Hash)

      issues = Array(body["detail"]).filter_map do |issue|
        next unless issue.is_a?(Hash)

        # Anything but plain strings and numbers could carry the user's text.
        location = Array(issue["loc"]).select { |part| part.is_a?(String) || part.is_a?(Integer) }.join(".")
        type = issue["type"] if issue["type"].is_a?(String)
        "#{location} #{type}".strip.presence
      end
      issues.any? ? " (#{issues.first(3).join("; ")})" : ""
    rescue JSON::ParserError
      ""
    end

    def retry_after(response)
      seconds = Integer(response["Retry-After"], exception: false)

      (seconds || DEFAULT_RETRY_AFTER).clamp(1, MAXIMUM_RETRY_AFTER)
    end

    def elapsed_milliseconds(started_at)
      ((Process.clock_gettime(Process::CLOCK_MONOTONIC) - started_at) * 1000).round
    end
  end
end
