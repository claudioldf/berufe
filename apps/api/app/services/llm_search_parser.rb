# frozen_string_literal: true

class LlmSearchParser
  MAXIMUM_EXPRESSION_LENGTH = 200
  MAXIMUM_NORMALIZED_REQUEST_LENGTH = WhatsappRequestMessageBuilder::MAXIMUM_REQUEST_LENGTH
  CACHE_TTL = 24.hours
  DEFAULT_STATE_CODE = "SC"
  DEFAULT_CITY = "Joinville"

  Location = Data.define(:state_code, :city, :neighborhood_code)
  Criteria = Data.define(:service_ids, :locations, :keywords, :normalized_request)

  class InvalidExpression < StandardError; end
  class LocationUnsupported < StandardError; end
  class LocationUnrecognized < StandardError; end
  class ProviderUnavailable < StandardError; end

  class ProviderRateLimited < ProviderUnavailable
    attr_reader :retry_after

    def initialize(retry_after:)
      @retry_after = retry_after
      super("LLM provider rate limit reached")
    end
  end

  def self.normalize_expression!(expression)
    raise InvalidExpression unless expression.is_a?(String)

    normalized = expression.squish
    raise InvalidExpression if normalized.blank? || normalized.length > MAXIMUM_EXPRESSION_LENGTH

    normalized
  end

  def initialize(
    client: Llm::Client.build,
    settings: Rails.configuration.x.berufe.environment,
    now: -> { Time.current },
    audit_recorder: PublicSearchAuditRecorder.new
  )
    @client = client
    @settings = settings
    @now = now
    @audit_recorder = audit_recorder
  end

  def call(expression:, audit_event: nil)
    normalized_expression = validate_expression!(expression)
    services = Service.publicly_active.ordered.to_a
    neighborhoods = Neighborhood.active.ordered.to_a
    prompt = LlmSearchPrompt.new(services:, neighborhoods:)
    audit_raw_response = nil
    audit_response_source = nil
    audit_provider_request_id = nil
    cache_key_digest = digest(
      "#{normalized_expression}\0#{prompt.digest}\0#{settings.llm_adapter}\0#{settings.openai_model}"
    )

    if (cached = cached_analysis(cache_key_digest))
      audit_raw_response = cached.raw_response
      audit_response_source = "cache"
      audit_provider_request_id = cached.provider_request_id
      criteria = criteria_from(cached.parsed_result, services:, neighborhoods:)
      audit_recorder.record_interpretation(
        event: audit_event,
        criteria:,
        raw_response: cached.raw_response,
        response_source: "cache",
        adapter: cached.adapter,
        model: cached.model,
        provider_request_id: cached.provider_request_id,
        prompt_digest: cached.prompt_digest
      )
      return criteria
    end

    response = client.parse(
      expression: normalized_expression,
      prompt: prompt.render,
      schema: response_schema(services),
      services:,
      neighborhoods:
    )
    audit_raw_response = response.raw_response
    audit_response_source = "provider"
    audit_provider_request_id = response.provider_request_id
    criteria = criteria_from(response.payload, services:, neighborhoods:)
    audit_recorder.record_interpretation(
      event: audit_event,
      criteria:,
      raw_response: response.raw_response,
      response_source: "provider",
      adapter: settings.llm_adapter,
      model: settings.openai_model,
      provider_request_id: response.provider_request_id,
      prompt_digest: prompt.digest
    )
    persist_analysis(
      cache_key_digest:,
      expression_digest: digest(normalized_expression),
      prompt_digest: prompt.digest,
      criteria:,
      response:
    )
    criteria
  rescue LocationUnsupported, LocationUnrecognized
    audit_recorder.record_failure(
      event: audit_event,
      status: "response_rejected",
      raw_response: audit_raw_response,
      response_source: audit_response_source,
      adapter: settings.llm_adapter,
      model: settings.openai_model,
      provider_request_id: audit_provider_request_id,
      prompt_digest: prompt&.digest
    )
    raise
  rescue Llm::Client::InvalidResponse => error
    audit_recorder.record_failure(
      event: audit_event,
      status: "response_rejected",
      raw_response: error.raw_response,
      response_source: "provider",
      adapter: settings.llm_adapter,
      model: settings.openai_model,
      provider_request_id: error.provider_request_id,
      prompt_digest: prompt&.digest
    )
    raise ProviderUnavailable, error.message
  rescue Llm::Client::RateLimited => error
    audit_recorder.record_failure(
      event: audit_event,
      status: "provider_rate_limited",
      adapter: settings.llm_adapter,
      model: settings.openai_model,
      prompt_digest: prompt&.digest
    )
    raise ProviderRateLimited.new(retry_after: error.retry_after)
  rescue Llm::Client::Unavailable => error
    audit_recorder.record_failure(
      event: audit_event,
      status: "provider_unavailable",
      adapter: settings.llm_adapter,
      model: settings.openai_model,
      prompt_digest: prompt&.digest
    )
    raise ProviderUnavailable, error.message
  end

  private

  attr_reader :client, :settings, :now, :audit_recorder

  def validate_expression!(expression)
    self.class.normalize_expression!(expression)
  end

  def criteria_from(payload, services:, neighborhoods:)
    value = payload.respond_to?(:to_h) ? payload.to_h.deep_stringify_keys : {}
    services_by_id = services.index_by { |service| service.id.to_s }
    service_ids = Array(value["service_ids"])
      .filter_map { |id| services_by_id[id.to_s]&.id }
      .uniq
    locations = parse_locations(value["locations"], neighborhoods:)
    keywords = Array(value["keywords"])
      .filter_map { |keyword| safe_keyword(keyword) }
      .uniq
      .first(10)
    normalized_request = WhatsappRequestMessageBuilder.normalize_request(value["normalized_request"])

    Criteria.new(service_ids:, locations:, keywords:, normalized_request:)
  end

  def parse_locations(values, neighborhoods:)
    raw_locations = Array(values).presence || [{}]
    locations = raw_locations.map do |raw_location|
      location = raw_location.respond_to?(:to_h) ? raw_location.to_h.deep_stringify_keys : {}
      state_code = location["state_code"].to_s.squish.presence&.upcase || DEFAULT_STATE_CODE
      city = location["city"].to_s.squish.presence || DEFAULT_CITY
      unless state_code == DEFAULT_STATE_CODE && PublicSearchText.normalize(city) == "joinville"
        raise LocationUnsupported
      end

      neighborhood_value = (location["neighborhood"] || location["neighborhood_code"]).to_s.squish.presence
      neighborhood = resolve_neighborhood(neighborhood_value, neighborhoods:)
      Location.new(
        state_code: DEFAULT_STATE_CODE,
        city: DEFAULT_CITY,
        neighborhood_code: neighborhood&.code
      )
    end

    locations.uniq
  end

  def resolve_neighborhood(value, neighborhoods:)
    return if value.blank?

    normalized = PublicSearchText.normalize(value)
    neighborhoods.find do |neighborhood|
      [neighborhood.code, neighborhood.name].any? do |candidate|
        PublicSearchText.normalize(candidate) == normalized
      end
    end || raise(LocationUnrecognized)
  end

  def safe_keyword(keyword)
    return unless keyword.is_a?(String)

    normalized = PublicSearchText.normalize(keyword).first(60).squish
    SearchEventQuerySanitizer.new.call(raw_term: keyword, normalized_term: normalized)
  end

  def response_schema(services)
    service_id_items = {type: "string"}
    service_id_items[:enum] = services.map { |service| service.id.to_s } if services.any?
    {
      type: "object",
      additionalProperties: false,
      properties: {
        service_ids: {
          type: "array",
          maxItems: 5,
          items: service_id_items
        },
        locations: {
          type: "array",
          maxItems: 8,
          items: {
            type: "object",
            additionalProperties: false,
            properties: {
              state_code: {type: %w[string null]},
              city: {type: %w[string null]},
              neighborhood: {type: %w[string null]}
            },
            required: %w[state_code city neighborhood]
          }
        },
        keywords: {
          type: "array",
          maxItems: 10,
          items: {type: "string", maxLength: 60}
        },
        normalized_request: {
          type: %w[string null],
          maxLength: MAXIMUM_NORMALIZED_REQUEST_LENGTH
        }
      },
      required: %w[service_ids locations keywords normalized_request]
    }
  end

  def cached_analysis(cache_key_digest)
    analysis = LlmSearchAnalysis.available(now.call).find_by(cache_key_digest:)
    analysis&.increment!(:cache_hit_count, touch: :updated_at)
    analysis
  rescue ActiveRecord::ActiveRecordError => error
    report_cache_error(error)
    nil
  end

  def persist_analysis(cache_key_digest:, expression_digest:, prompt_digest:, criteria:, response:)
    LlmSearchAnalysis.create!(
      cache_key_digest:,
      expression_digest:,
      adapter: settings.llm_adapter,
      model: settings.openai_model,
      prompt_digest:,
      raw_response: response.raw_response,
      parsed_result: {
        service_ids: criteria.service_ids,
        locations: criteria.locations.map(&:to_h),
        keywords: criteria.keywords,
        normalized_request: criteria.normalized_request
      },
      provider_request_id: response.provider_request_id,
      input_tokens: response.input_tokens,
      cached_input_tokens: response.cached_input_tokens,
      output_tokens: response.output_tokens,
      latency_ms: response.latency_ms,
      expires_at: now.call + CACHE_TTL
    )
  rescue ActiveRecord::RecordNotUnique
    nil
  rescue ActiveRecord::ActiveRecordError => error
    report_cache_error(error)
  end

  def digest(value)
    SessionSecurityDigest.call(purpose: "llm_search", value:)
  end

  def report_cache_error(error)
    Rails.error.report(error)
    Rails.logger.error(
      "llm_search_cache_failed class=#{error.class} request_id=#{Current.request_id}"
    )
  end
end
