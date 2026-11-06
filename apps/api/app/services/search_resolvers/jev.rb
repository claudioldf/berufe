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
      questions = questions_for(services:, neighborhoods:, default_location:)
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
        if city_neighborhoods.any?
          follow_up = post(
            state: expression,
            questions: {"neighborhood" => neighborhood_question(city_neighborhoods, city_name: city.city)}
          )
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
      Digest::SHA256.hexdigest(
        JSON.generate(questions_for(services:, neighborhoods:, default_location:))
      )
    end

    private

    attr_reader :api_key, :timeout_seconds, :min_confidence, :secondary_probability, :endpoint, :http

    def questions_for(services:, neighborhoods:, default_location:)
      questions = {}
      if services.any?
        questions["wants_service"] = {
          "type" => "noul",
          "instructions" => "O texto descreve um serviço ou o tipo de profissional que a pessoa quer contratar?"
        }
        questions["service"] = {
          "type" => "choice",
          "instructions" => "Qual serviço do catálogo melhor atende ao pedido?",
          "criteria" => services.to_h do |service|
            [service.slug, {"nome" => service.name, "aliases" => service.aliases, "descricao" => service.description}]
          end
        }
      end
      questions["mentions_city"] = {
        "type" => "noul",
        "instructions" => "O texto cita explicitamente o nome de uma cidade? Bairros e regiões dentro da cidade não contam."
      }
      questions["city"] = {
        "type" => "choice",
        "instructions" => "Qual cidade o texto cita?",
        "criteria" => supported_locations.to_h { |location|
          [location.city_code, "#{location.city}/#{location.state_code}"]
        }.merge(OTHER_CITY => "Uma cidade que não está na lista")
      }
      if neighborhoods.any?
        questions["neighborhood"] = neighborhood_question(neighborhoods, city_name: default_location.city)
      end
      questions
    end

    def neighborhood_question(neighborhoods, city_name:)
      {
        "type" => "choice",
        "instructions" => "Qual bairro de #{city_name} o texto cita?",
        "criteria" => neighborhoods.to_h { |neighborhood| [neighborhood.code, neighborhood.name] }
          .merge(NO_NEIGHBORHOOD => "Nenhum bairro é citado")
      }
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
        value["choice"].is_a?(String) && value["confidence"].is_a?(Numeric) && value["probabilities"].is_a?(Hash)
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
      parse(response)
    rescue IOError, SocketError, SystemCallError, Timeout::Error => error
      Rails.error.report(error)
      raise ::Llm::Client::Unavailable, "JEV request failed"
    end

    def parse(response)
      status = response.code.to_i
      raise ::Llm::Client::RateLimited.new(retry_after: retry_after(response)) if [429, 529].include?(status)
      raise ::Llm::Client::Unavailable, "JEV returned HTTP #{status}" unless status.between?(200, 299)

      body = JSON.parse(response.body)
      unless body.is_a?(Hash) && body["answers"].is_a?(Hash)
        raise ::Llm::Client::InvalidResponse.new(raw_response: response.body.to_s)
      end

      body
    rescue JSON::ParserError
      raise ::Llm::Client::InvalidResponse.new(raw_response: response.body.to_s)
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
