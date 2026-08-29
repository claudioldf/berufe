# frozen_string_literal: true

class AddSelfServiceAccessToDataErasureRequests < ActiveRecord::Migration[8.0]
  def change
    change_column_null :data_erasure_requests, :target_user_account_id, true
    add_column :data_erasure_requests, :request_source, :string,
      limit: 20, null: false, default: "support"
    add_column :data_erasure_requests, :confirmation_version, :string, limit: 16
    add_column :data_erasure_requests, :status_token_hash, :string, limit: 64
    add_column :data_erasure_requests, :status_token_ciphertext, :text

    add_index :data_erasure_requests, :status_token_hash, unique: true
    add_check_constraint :data_erasure_requests,
      "request_source IN ('support', 'self_service')",
      name: "data_erasure_requests_known_source"
    add_check_constraint :data_erasure_requests,
      "status_token_hash IS NULL OR status_token_hash ~ '^[0-9a-f]{64}$'",
      name: "data_erasure_requests_status_digest_format"
    add_check_constraint :data_erasure_requests,
      "(status_token_hash IS NULL) = (status_token_ciphertext IS NULL)",
      name: "data_erasure_requests_status_token_pair"
    add_check_constraint :data_erasure_requests,
      "request_source != 'self_service' OR " \
        "(confirmation_version IS NOT NULL AND status_token_hash IS NOT NULL)",
      name: "data_erasure_requests_self_service_evidence"
  end
end
