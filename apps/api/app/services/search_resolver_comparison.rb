# frozen_string_literal: true

# Runs one search expression through every resolver for side-by-side testing
# (see `bin/rails "search:compare[...]"`). Nothing is cached or audited, so
# comparing never skews real search data.
class SearchResolverComparison
  RESOLVER_NAMES = %w[llm jev].freeze

  Result = Data.define(
    :name, :adapter, :model, :services, :locations, :keywords, :normalized_request,
    :signals, :latency_ms, :error
  )

  # Remembers the provider response so the signals behind a choice (JEV's
  # probabilities) can be shown next to the mapped criteria.
  class RecordingResolver
    attr_reader :response

    def initialize(resolver)
      @resolver = resolver
    end

    def adapter = @resolver.adapter

    def model = @resolver.model

    def prompt_digest(**) = @resolver.prompt_digest(**)

    def call(**)
      @response = @resolver.call(**)
    end
  end

  def initialize(names: RESOLVER_NAMES, builder: SearchResolvers.method(:build))
    @names = names
    @builder = builder
  end

  def call(expression:)
    names.map { |name| run(name, expression) }
  end

  private

  attr_reader :names, :builder

  def run(name, expression)
    started_at = Process.clock_gettime(Process::CLOCK_MONOTONIC)
    resolver = RecordingResolver.new(builder.call(name:))
    criteria = LlmSearchParser.new(resolver:).call(expression:, use_cache: false)
    result_for(name, resolver, criteria, elapsed_since(started_at))
  rescue => error
    Result.new(
      name:, adapter: nil, model: nil, services: [], locations: [], keywords: [],
      normalized_request: nil, signals: nil, latency_ms: elapsed_since(started_at),
      error: "#{error.class.name.demodulize}: #{error.message}"
    )
  end

  def result_for(name, resolver, criteria, latency_ms)
    Result.new(
      name:,
      adapter: resolver.adapter,
      model: resolver.model,
      services: service_names(criteria.service_ids),
      locations: location_labels(criteria.locations),
      keywords: criteria.keywords,
      normalized_request: criteria.normalized_request,
      signals: signals_for(name, resolver.response),
      latency_ms:,
      error: nil
    )
  end

  def service_names(ids)
    names_by_id = Service.where(id: ids).pluck(:id, :name).to_h
    ids.filter_map { |id| names_by_id[id] }
  end

  def location_labels(locations)
    neighborhoods = Neighborhood.where(code: locations.filter_map(&:neighborhood_code)).pluck(:code, :name).to_h
    locations.map do |location|
      [neighborhoods[location.neighborhood_code], "#{location.city}/#{location.state_code}"].compact.join(", ")
    end
  end

  # "wants_service=0.97 service=eletricista(0.93) ..." for every answer JEV gave.
  def signals_for(name, response)
    return unless name == "jev" && response

    JSON.parse(response.raw_response).flat_map do |body|
      body.fetch("answers").map do |id, answer|
        if answer["type"] == "noul"
          "#{id}=#{answer["noul"].round(2)}"
        else
          "#{id}=#{answer["choice"]}(#{answer["confidence"].round(2)})"
        end
      end
    end.join(" ")
  rescue JSON::ParserError, KeyError, NoMethodError
    nil
  end

  def elapsed_since(started_at)
    ((Process.clock_gettime(Process::CLOCK_MONOTONIC) - started_at) * 1000).round
  end
end
