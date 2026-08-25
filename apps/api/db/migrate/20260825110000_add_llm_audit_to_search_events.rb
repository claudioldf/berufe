# frozen_string_literal: true

class AddLlmAuditToSearchEvents < ActiveRecord::Migration[8.1]
  def change
    change_table :search_events, bulk: true do |table|
      table.text :input_prompt
      table.text :raw_llm_response
      table.jsonb :parsed_response
      table.string :audit_status, limit: 32
      table.string :response_source, limit: 16
      table.string :llm_adapter, limit: 24
      table.string :llm_model, limit: 80
      table.string :llm_provider_request_id, limit: 120
      table.string :llm_prompt_digest, limit: 64
      table.boolean :reportable, null: false, default: true
    end

    add_column :llm_search_analyses, :raw_response, :text

    add_check_constraint :search_events,
      "input_prompt IS NULL OR char_length(input_prompt) BETWEEN 1 AND 200",
      name: "search_events_input_prompt_length"
    add_check_constraint :search_events,
      "audit_status IS NULL OR audit_status IN ('processing', 'completed', 'application_rate_limited', 'provider_rate_limited', 'provider_unavailable', 'response_rejected', 'search_failed')",
      name: "search_events_known_audit_status"
    add_check_constraint :search_events,
      "response_source IS NULL OR response_source IN ('provider', 'cache')",
      name: "search_events_known_response_source"
    add_check_constraint :search_events,
      "llm_prompt_digest IS NULL OR llm_prompt_digest ~ '^[0-9a-f]{64}$'",
      name: "search_events_llm_prompt_digest_format"
    add_check_constraint :search_events,
      "input_prompt IS NOT NULL OR (raw_llm_response IS NULL AND parsed_response IS NULL AND response_source IS NULL AND llm_adapter IS NULL AND llm_model IS NULL AND llm_provider_request_id IS NULL AND llm_prompt_digest IS NULL)",
      name: "search_events_audit_fields_require_prompt"

    add_index :search_events,
      %i[created_at id],
      order: {created_at: :desc, id: :desc},
      where: "input_prompt IS NOT NULL",
      name: "index_search_events_on_recent_llm_audits"
  end
end
