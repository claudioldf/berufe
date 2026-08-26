# frozen_string_literal: true

class CreateLlmSearchInfrastructure < ActiveRecord::Migration[8.1]
  def change
    create_table :llm_search_analyses, id: :uuid do |table|
      table.string :cache_key_digest, limit: 64, null: false
      table.string :expression_digest, limit: 64, null: false
      table.string :adapter, limit: 24, null: false
      table.string :model, limit: 80, null: false
      table.string :prompt_digest, limit: 64, null: false
      table.jsonb :parsed_result, null: false
      table.string :provider_request_id, limit: 120
      table.integer :input_tokens
      table.integer :cached_input_tokens
      table.integer :output_tokens
      table.integer :latency_ms
      table.integer :cache_hit_count, default: 0, null: false
      table.datetime :expires_at, null: false
      table.timestamps

      table.index :cache_key_digest, unique: true
      table.index :expires_at
      table.check_constraint "cache_key_digest ~ '^[0-9a-f]{64}$'", name: "llm_search_analyses_cache_digest_format"
      table.check_constraint "expression_digest ~ '^[0-9a-f]{64}$'", name: "llm_search_analyses_expression_digest_format"
      table.check_constraint "prompt_digest ~ '^[0-9a-f]{64}$'", name: "llm_search_analyses_prompt_digest_format"
      table.check_constraint "cache_hit_count >= 0", name: "llm_search_analyses_nonnegative_hits"
    end

    create_table :public_search_rate_limit_counters, id: :uuid do |table|
      table.string :subject_digest, limit: 64, null: false
      table.datetime :window_started_at, null: false
      table.integer :request_count, default: 0, null: false
      table.timestamps

      table.index %i[subject_digest window_started_at],
        unique: true,
        name: "idx_public_search_rate_limits_subject_window"
      table.index :window_started_at
      table.check_constraint "subject_digest ~ '^[0-9a-f]{64}$'", name: "public_search_rate_limits_digest_format"
      table.check_constraint "request_count >= 0", name: "public_search_rate_limits_nonnegative_count"
    end
  end
end
