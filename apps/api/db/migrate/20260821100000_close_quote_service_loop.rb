# frozen_string_literal: true

class CloseQuoteServiceLoop < ActiveRecord::Migration[8.1]
  def up
    # Quote data created before this feature did not contain the required
    # customer phone snapshot. It was explicitly treated as disposable test
    # data for this migration, so starting from a clean quote set is safer than
    # inventing contact information that was never supplied.
    execute "DELETE FROM quotes"

    create_table :customers, id: :uuid, default: -> { "gen_random_uuid()" } do |table|
      table.references :professional,
        type: :uuid,
        null: false,
        foreign_key: {to_table: :professional_profiles}
      table.string :name, null: false, limit: 80
      table.string :whatsapp_e164, null: false, limit: 14
      table.string :email, limit: 254
      table.datetime :email_verified_at
      table.timestamps
    end

    add_index :customers, %i[professional_id name], name: "index_customers_on_professional_and_name"
    add_index :customers, %i[id professional_id], unique: true, name: "index_customers_on_id_and_professional"
    add_check_constraint :customers,
      "char_length(btrim(name)) BETWEEN 1 AND 80",
      name: "customers_name_length"
    add_check_constraint :customers,
      "whatsapp_e164 ~ '^\\+55[1-9][0-9]9[0-9]{8}$'",
      name: "customers_brazilian_mobile"

    add_reference :quotes, :customer, type: :uuid
    add_column :quotes, :customer_phone_e164, :string, limit: 14
    add_column :quotes, :customer_email, :string, limit: 254
    add_column :quotes, :service_address, :string, limit: 240
    add_column :quotes, :scheduled_on, :date
    add_column :quotes, :customer_decided_at, :datetime
    add_column :quotes, :customer_decision_message, :text
    add_column :quotes, :terms_accepted_at, :datetime
    add_column :quotes, :lock_version, :integer, null: false, default: 0

    change_column_null :quotes, :customer_id, false
    change_column_null :quotes, :customer_phone_e164, false
    add_index :quotes, %i[customer_id professional_id], name: "index_quotes_on_customer_and_professional"
    execute <<~SQL
      ALTER TABLE quotes
      ADD CONSTRAINT quotes_customer_owned_by_professional
      FOREIGN KEY (customer_id, professional_id)
      REFERENCES customers(id, professional_id)
    SQL
    add_check_constraint :quotes,
      "customer_phone_e164 ~ '^\\+55[1-9][0-9]9[0-9]{8}$'",
      name: "quotes_customer_brazilian_mobile"
    add_check_constraint :quotes,
      "customer_decision_message IS NULL OR char_length(btrim(customer_decision_message)) BETWEEN 1 AND 700",
      name: "quotes_customer_decision_message_length"

    remove_check_constraint :quotes, name: "quotes_known_status"
    add_check_constraint :quotes,
      "status IN ('draft', 'shared', 'change_requested', 'approved', 'declined')",
      name: "quotes_known_status"
    remove_check_constraint :quotes, name: "quotes_consistent_share_state"
    add_check_constraint :quotes,
      "(status = 'draft' AND share_token_hash IS NULL AND share_token_ciphertext IS NULL AND shared_at IS NULL) OR " \
        "(status <> 'draft' AND share_token_hash IS NOT NULL AND share_token_ciphertext IS NOT NULL AND shared_at IS NOT NULL)",
      name: "quotes_consistent_share_state"

    create_table :service_jobs, id: :uuid, default: -> { "gen_random_uuid()" } do |table|
      table.references :quote, type: :uuid, null: false, foreign_key: true, index: {unique: true}
      table.string :status, null: false, default: "approved", limit: 24
      table.datetime :completion_requested_at
      table.datetime :completion_issue_at
      table.text :completion_issue_message
      table.datetime :completed_at
      table.datetime :cancelled_at
      table.text :cancellation_reason
      table.timestamps
    end

    add_index :service_jobs, %i[status updated_at], name: "index_service_jobs_on_status_and_updated_at"
    add_check_constraint :service_jobs,
      "status IN ('approved', 'completion_requested', 'completion_issue', 'completed', 'cancelled')",
      name: "service_jobs_known_status"
    add_check_constraint :service_jobs,
      "completion_issue_message IS NULL OR char_length(btrim(completion_issue_message)) BETWEEN 1 AND 700",
      name: "service_jobs_completion_issue_message_length"
    add_check_constraint :service_jobs,
      "cancellation_reason IS NULL OR char_length(btrim(cancellation_reason)) BETWEEN 1 AND 700",
      name: "service_jobs_cancellation_reason_length"

    create_table :customer_recommendation_requests, id: :uuid, default: -> { "gen_random_uuid()" } do |table|
      table.references :service_job, type: :uuid, null: false, foreign_key: true,
        index: {unique: true, name: "idx_recommendation_requests_unique_job"}
      table.string :token_hash, null: false, limit: 64
      table.text :token_ciphertext
      table.string :email_fingerprint, null: false, limit: 64
      table.string :status, null: false, default: "open", limit: 16
      table.datetime :expires_at, null: false
      table.datetime :sent_at
      table.datetime :completed_at
      table.timestamps
    end

    add_index :customer_recommendation_requests, :token_hash,
      unique: true,
      name: "idx_recommendation_requests_unique_token"
    add_index :customer_recommendation_requests, %i[status expires_at],
      name: "idx_recommendation_requests_status_expiry"
    add_check_constraint :customer_recommendation_requests,
      "status IN ('open', 'completed', 'expired')",
      name: "customer_recommendation_requests_known_status"

    create_table :customer_recommendations, id: :uuid, default: -> { "gen_random_uuid()" } do |table|
      table.references :service_job, type: :uuid, null: false, foreign_key: true,
        index: {unique: true, name: "idx_customer_recommendations_unique_job"}
      table.references :customer, type: :uuid, null: false, foreign_key: true
      table.string :display_name, null: false, limit: 80
      table.text :recommendation_text, null: false
      table.string :email_fingerprint, null: false, limit: 64
      table.datetime :email_verified_at, null: false
      table.datetime :service_confirmed_at, null: false
      table.datetime :publication_authorized_at, null: false
      table.datetime :submitted_at, null: false
      table.timestamps
    end

    add_check_constraint :customer_recommendations,
      "char_length(btrim(display_name)) BETWEEN 1 AND 80",
      name: "customer_recommendations_display_name_length"
    add_check_constraint :customer_recommendations,
      "char_length(btrim(recommendation_text)) BETWEEN 1 AND 700",
      name: "customer_recommendations_text_length"
  end

  def down
    drop_table :customer_recommendations
    drop_table :customer_recommendation_requests
    drop_table :service_jobs

    remove_check_constraint :quotes, name: "quotes_customer_decision_message_length"
    remove_check_constraint :quotes, name: "quotes_customer_brazilian_mobile"
    remove_check_constraint :quotes, name: "quotes_consistent_share_state"
    remove_check_constraint :quotes, name: "quotes_known_status"
    execute "ALTER TABLE quotes DROP CONSTRAINT quotes_customer_owned_by_professional"
    remove_index :quotes, name: "index_quotes_on_customer_and_professional"
    remove_column :quotes, :lock_version
    remove_column :quotes, :terms_accepted_at
    remove_column :quotes, :customer_decision_message
    remove_column :quotes, :customer_decided_at
    remove_column :quotes, :scheduled_on
    remove_column :quotes, :service_address
    remove_column :quotes, :customer_email
    remove_column :quotes, :customer_phone_e164
    remove_reference :quotes, :customer
    add_check_constraint :quotes,
      "status IN ('draft', 'shared')",
      name: "quotes_known_status"
    add_check_constraint :quotes,
      "(status = 'draft' AND share_token_hash IS NULL AND share_token_ciphertext IS NULL AND shared_at IS NULL) OR " \
        "(status = 'shared' AND share_token_hash IS NOT NULL AND share_token_ciphertext IS NOT NULL AND shared_at IS NOT NULL)",
      name: "quotes_consistent_share_state"

    drop_table :customers
  end
end
