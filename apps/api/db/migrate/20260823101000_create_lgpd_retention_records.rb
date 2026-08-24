# frozen_string_literal: true

class CreateLgpdRetentionRecords < ActiveRecord::Migration[8.0]
  def change
    create_table :data_erasure_requests, id: :uuid do |t|
      t.uuid :target_user_account_id, null: false
      t.string :subject_digest, limit: 64, null: false
      t.string :ticket_reference, limit: 100, null: false
      t.string :status, limit: 16, null: false, default: "requested"
      t.string :verification_method, limit: 32, null: false
      t.datetime :requested_at, null: false
      t.datetime :verified_at, null: false
      t.datetime :unpublished_at, null: false
      t.datetime :completed_at
      t.datetime :retained_until, null: false
      t.string :failure_code, limit: 40
      t.timestamps
    end

    add_index :data_erasure_requests, :target_user_account_id,
      unique: true,
      where: "status IN ('requested', 'processing', 'failed')",
      name: "idx_data_erasure_requests_one_active_account"
    add_index :data_erasure_requests, :retained_until
    add_index :data_erasure_requests, :subject_digest
    add_check_constraint :data_erasure_requests,
      "subject_digest ~ '^[0-9a-f]{64}$'",
      name: "data_erasure_requests_digest_format"
    add_check_constraint :data_erasure_requests,
      "status IN ('requested', 'processing', 'failed', 'completed')",
      name: "data_erasure_requests_known_status"
    add_check_constraint :data_erasure_requests,
      "ticket_reference ~ '^[A-Za-z0-9._/-]{1,100}$'",
      name: "data_erasure_requests_ticket_format"

    create_table :legal_retention_records, id: :uuid do |t|
      t.string :subject_digest, limit: 64, null: false
      t.string :record_type, limit: 48, null: false
      t.datetime :occurred_at, null: false
      t.jsonb :metadata, null: false, default: {}
      t.datetime :retained_until, null: false
      t.timestamps
    end

    add_index :legal_retention_records, :subject_digest
    add_index :legal_retention_records, :retained_until
    add_check_constraint :legal_retention_records,
      "subject_digest ~ '^[0-9a-f]{64}$'",
      name: "legal_retention_records_digest_format"
    add_check_constraint :legal_retention_records,
      "jsonb_typeof(metadata) = 'object'",
      name: "legal_retention_records_metadata_object"
  end
end
