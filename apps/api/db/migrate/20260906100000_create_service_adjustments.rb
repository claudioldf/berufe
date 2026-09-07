# frozen_string_literal: true

class CreateServiceAdjustments < ActiveRecord::Migration[8.1]
  ADJUSTMENT_STATUSES = %w[draft awaiting_response change_requested approved declined cancelled].freeze
  ITEM_KINDS = %w[additional_service material_charge material_reimbursement credit].freeze

  def change
    create_table :service_adjustments, id: :uuid, default: -> { "gen_random_uuid()" } do |table|
      table.references :service_job, type: :uuid, null: false, foreign_key: {on_delete: :cascade}
      table.integer :adjustment_number, null: false
      table.string :status, null: false, default: "draft", limit: 24
      table.string :title, null: false, limit: 120
      table.text :description
      table.text :schedule_impact
      table.date :incurred_on
      table.decimal :total_amount, null: false, default: 0, precision: 14, scale: 2
      table.datetime :shared_at
      table.datetime :customer_decided_at
      table.text :customer_decision_message
      table.datetime :terms_accepted_at
      table.integer :accepted_revision
      table.string :accepted_customer_name, limit: 80
      table.string :accepted_customer_phone_e164, limit: 20
      table.string :accepted_customer_email, limit: 254
      table.integer :lock_version, null: false, default: 0
      table.timestamps
    end

    add_index :service_adjustments, %i[service_job_id adjustment_number], unique: true
    add_index :service_adjustments, %i[service_job_id status updated_at], name: "idx_service_adjustments_job_status_updated"
    add_check_constraint :service_adjustments,
      "status IN (#{ADJUSTMENT_STATUSES.map { |status| quote(status) }.join(", ")})",
      name: "service_adjustments_known_status"
    add_check_constraint :service_adjustments,
      "adjustment_number > 0",
      name: "service_adjustments_positive_number"
    add_check_constraint :service_adjustments,
      "char_length(btrim(title)) BETWEEN 1 AND 120",
      name: "service_adjustments_title_length"
    add_check_constraint :service_adjustments,
      "description IS NULL OR char_length(btrim(description)) BETWEEN 1 AND 700",
      name: "service_adjustments_description_length"
    add_check_constraint :service_adjustments,
      "schedule_impact IS NULL OR char_length(btrim(schedule_impact)) BETWEEN 1 AND 300",
      name: "service_adjustments_schedule_impact_length"
    add_check_constraint :service_adjustments,
      "customer_decision_message IS NULL OR char_length(btrim(customer_decision_message)) BETWEEN 1 AND 700",
      name: "service_adjustments_decision_message_length"
    add_check_constraint :service_adjustments,
      "accepted_revision IS NULL OR accepted_revision >= 0",
      name: "service_adjustments_nonnegative_accepted_revision"

    create_table :service_adjustment_items, id: :uuid, default: -> { "gen_random_uuid()" } do |table|
      table.references :service_adjustment, type: :uuid, null: false, foreign_key: {on_delete: :cascade}
      table.string :kind, null: false, limit: 32
      table.string :description, null: false, limit: 160
      table.decimal :quantity, null: false, precision: 12, scale: 3
      table.string :unit, null: false, limit: 20
      table.decimal :unit_price, null: false, precision: 14, scale: 2
      table.decimal :line_total, null: false, precision: 14, scale: 2
      table.integer :sort_order, null: false
      table.timestamps
    end

    add_index :service_adjustment_items, %i[service_adjustment_id sort_order], unique: true,
      name: "idx_service_adjustment_items_order"
    add_check_constraint :service_adjustment_items,
      "kind IN (#{ITEM_KINDS.map { |kind| quote(kind) }.join(", ")})",
      name: "service_adjustment_items_known_kind"
    add_check_constraint :service_adjustment_items,
      "quantity > 0",
      name: "service_adjustment_items_positive_quantity"
    add_check_constraint :service_adjustment_items,
      "unit_price >= 0",
      name: "service_adjustment_items_nonnegative_price"
    add_check_constraint :service_adjustment_items,
      "(kind = 'credit' AND line_total <= 0) OR (kind <> 'credit' AND line_total >= 0)",
      name: "service_adjustment_items_signed_total"
    add_check_constraint :service_adjustment_items,
      "sort_order >= 0",
      name: "service_adjustment_items_nonnegative_order"

    create_table :service_adjustment_receipts, id: :uuid, default: -> { "gen_random_uuid()" } do |table|
      table.references :service_adjustment_item, type: :uuid, null: false,
        foreign_key: {on_delete: :cascade}, index: {unique: true}
      table.references :media_upload, type: :uuid, null: false,
        foreign_key: {on_delete: :restrict}, index: {unique: true}
      table.text :private_key, null: false
      table.string :content_type, null: false, limit: 40
      table.bigint :byte_size, null: false
      table.integer :width, null: false
      table.integer :height, null: false
      table.datetime :attached_at, null: false
      table.timestamps
    end

    add_index :service_adjustment_receipts, :private_key, unique: true
    add_check_constraint :service_adjustment_receipts,
      "content_type IN ('image/jpeg', 'image/png')",
      name: "service_adjustment_receipts_supported_type"
    add_check_constraint :service_adjustment_receipts,
      "byte_size > 0 AND width > 0 AND height > 0",
      name: "service_adjustment_receipts_positive_dimensions"

    create_table :service_adjustment_change_requests, id: :uuid, default: -> { "gen_random_uuid()" } do |table|
      table.references :service_adjustment, type: :uuid, null: false, foreign_key: {on_delete: :cascade}
      table.integer :requested_revision, null: false
      table.text :message, null: false
      table.datetime :requested_at, null: false
      table.timestamps
    end

    add_index :service_adjustment_change_requests,
      %i[service_adjustment_id requested_revision], unique: true,
      name: "idx_adjustment_change_requests_revision"
    add_index :service_adjustment_change_requests,
      %i[service_adjustment_id requested_at id],
      order: {requested_at: :desc, id: :desc},
      name: "idx_adjustment_change_requests_order"
    add_check_constraint :service_adjustment_change_requests,
      "requested_revision >= 0",
      name: "adjustment_change_requests_nonnegative_revision"
    add_check_constraint :service_adjustment_change_requests,
      "char_length(btrim(message)) BETWEEN 1 AND 700",
      name: "adjustment_change_requests_message_length"

    remove_check_constraint :media_uploads, name: "media_uploads_known_purpose"
    add_check_constraint :media_uploads,
      "purpose IN ('profile_photo', 'portfolio_image', 'verification_identity', 'service_adjustment_receipt')",
      name: "media_uploads_known_purpose"

    remove_check_constraint :notifications, name: "notifications_known_type"
    add_check_constraint :notifications,
      <<~SQL.squish,
        notification_type IN (
          'profile_moderation_hidden', 'profile_moderation_restored',
          'verification_request_moderation_approved', 'verification_request_moderation_rejected',
          'relationship_request_received', 'relationship_request_accepted',
          'relationship_request_declined', 'quote_change_requested', 'quote_approved',
          'quote_declined', 'service_completion_issue_reported',
          'service_adjustment_change_requested', 'service_adjustment_approved',
          'service_adjustment_declined', 'customer_recommendation_published'
        )
      SQL
      name: "notifications_known_type"

    remove_check_constraint :notifications, name: "notifications_route_params_match_type"
    add_check_constraint :notifications,
      <<~SQL.squish,
        CASE
          WHEN notification_type IN ('quote_change_requested', 'quote_approved', 'quote_declined')
            THEN route_params = jsonb_build_object('quote_id', route_params ->> 'quote_id')
              AND COALESCE((route_params ->> 'quote_id') ~* '^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$', FALSE)
          WHEN notification_type IN (
            'service_completion_issue_reported', 'service_adjustment_change_requested',
            'service_adjustment_approved', 'service_adjustment_declined'
          )
            THEN route_params = jsonb_build_object('service_job_id', route_params ->> 'service_job_id')
              AND COALESCE((route_params ->> 'service_job_id') ~* '^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$', FALSE)
          ELSE route_params = '{}'::jsonb
        END
      SQL
      name: "notifications_route_params_match_type"
  end
end
