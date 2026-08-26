# frozen_string_literal: true

class AdminSearchAuditSerializer
  def initialize(result)
    @result = result
  end

  def as_json(*)
    {
      items: result.events.map { |event| serialize_event(event) },
      summary: result.summary,
      meta: {
        page: result.page,
        per_page: result.per_page,
        total_count: result.total_count,
        total_pages: result.total_pages
      }
    }
  end

  private

  attr_reader :result

  def serialize_event(event)
    {
      id: event.id,
      input_prompt: event.input_prompt,
      raw_llm_response: event.raw_llm_response,
      parsed_response: event.parsed_response,
      status: event.audit_status,
      response_source: event.response_source,
      adapter: event.llm_adapter,
      model: event.llm_model,
      provider_request_id: event.llm_provider_request_id,
      prompt_digest: event.llm_prompt_digest,
      result_count: event.result_count,
      created_at: event.created_at.iso8601
    }
  end
end
