# frozen_string_literal: true

class PublicSearchAuditRecorder
  def start(expression:, city_code:)
    normalized_expression = LlmSearchParser.normalize_expression!(expression)
    SearchEvent.create!(
      input_prompt: normalized_expression,
      city_code:,
      result_count: 0,
      reportable: false,
      audit_status: "processing"
    )
  rescue ActiveRecord::ActiveRecordError => error
    report_persistence_error(error)
    nil
  end

  def record_interpretation(
    event:,
    criteria:,
    raw_response:,
    response_source:,
    adapter:,
    model:,
    provider_request_id:,
    prompt_digest:
  )
    update_event(
      event,
      raw_llm_response: raw_response,
      parsed_response: self.class.parsed_response(criteria),
      response_source:,
      llm_adapter: adapter,
      llm_model: model,
      llm_provider_request_id: provider_request_id,
      llm_prompt_digest: prompt_digest
    )
  rescue ActiveRecord::ActiveRecordError => error
    report_persistence_error(error)
    nil
  end

  def record_failure(
    event:,
    status:,
    raw_response: nil,
    response_source: nil,
    adapter: nil,
    model: nil,
    provider_request_id: nil,
    prompt_digest: nil
  )
    optional_attributes = {
      raw_llm_response: raw_response,
      response_source:,
      llm_adapter: adapter,
      llm_model: model,
      llm_provider_request_id: provider_request_id,
      llm_prompt_digest: prompt_digest
    }.compact
    update_event(
      event,
      **optional_attributes,
      audit_status: status,
      result_count: 0,
      reportable: false
    )
  end

  def self.parsed_response(criteria)
    services_by_id = Service.where(id: criteria.service_ids).index_by(&:id)
    neighborhoods_by_code = Neighborhood
      .where(code: criteria.locations.filter_map(&:neighborhood_code))
      .index_by(&:code)

    {
      service_ids: criteria.service_ids,
      services: criteria.service_ids.filter_map do |service_id|
        service = services_by_id[service_id]
        {id: service.id, name: service.name} if service
      end,
      locations: criteria.locations.map do |location|
        neighborhood = neighborhoods_by_code[location.neighborhood_code]
        {
          city_code: location.city_code,
          state_code: location.state_code,
          city: location.city,
          neighborhood: neighborhood && {code: neighborhood.code, name: neighborhood.name}
        }
      end,
      keywords: criteria.keywords,
      normalized_request: criteria.normalized_request
    }
  end

  private

  def update_event(event, **attributes)
    return unless event

    event.update!(attributes)
    event
  rescue ActiveRecord::ActiveRecordError => error
    report_persistence_error(error)
    nil
  end

  def report_persistence_error(error)
    Rails.error.report(error)
    Rails.logger.error(
      "public_search_audit_recording_failed class=#{error.class} request_id=#{Current.request_id}"
    )
  end
end
