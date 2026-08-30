# frozen_string_literal: true

class Notification < ApplicationRecord
  TYPES = %w[
    profile_moderation_approved
    profile_moderation_rejected
    profile_moderation_hidden
    profile_moderation_restored
    profile_photo_moderation_approved
    profile_photo_moderation_rejected
    profile_photo_moderation_hidden
    profile_photo_moderation_restored
    portfolio_item_moderation_approved
    portfolio_item_moderation_rejected
    portfolio_item_moderation_hidden
    portfolio_item_moderation_restored
    verification_request_moderation_approved
    verification_request_moderation_rejected
    relationship_request_received
    relationship_request_accepted
    relationship_request_declined
    quote_change_requested
    quote_approved
    quote_declined
    service_completion_confirmed
    service_completion_issue_reported
    customer_recommendation_published
  ].freeze
  STATUSES = %w[unread read].freeze
  QUOTE_TYPES = %w[quote_change_requested quote_approved quote_declined].freeze
  SERVICE_JOB_TYPES = %w[service_completion_confirmed service_completion_issue_reported].freeze

  belongs_to :recipient_user_account, class_name: "UserAccount", inverse_of: :notifications

  scope :unread, -> { where(status: "unread") }
  scope :newest_first, -> { order(occurred_at: :desc, id: :desc) }

  validates :notification_type, inclusion: {in: TYPES}
  validates :status, inclusion: {in: STATUSES}
  validates :title, presence: true, length: {in: 1..120}
  validates :description, presence: true, length: {in: 1..240}
  validate :route_params_match_notification_type
  validates :idempotency_key, presence: true, length: {in: 1..255}
  validates :occurred_at, presence: true
  validate :read_state_is_consistent
  validate :read_status_is_irreversible, on: :update

  def unread?
    status == "unread"
  end

  def read?
    status == "read"
  end

  private

  def read_state_is_consistent
    return if (unread? && read_at.nil?) || (read? && read_at.present?)

    errors.add(:read_at, :invalid)
  end

  def read_status_is_irreversible
    return unless status_in_database == "read" && status == "unread"

    errors.add(:status, :readonly)
  end

  def route_params_match_notification_type
    expected_key = if notification_type.in?(QUOTE_TYPES)
      "quote_id"
    elsif notification_type.in?(SERVICE_JOB_TYPES)
      "service_job_id"
    end
    expected_keys = expected_key ? [expected_key] : []
    unless route_params.is_a?(Hash) && route_params.keys.sort == expected_keys
      errors.add(:route_params, :invalid)
      return
    end
    return unless expected_key
    return if route_params.fetch(expected_key).to_s.match?(PublicInteractionToken::UUID_PATTERN)

    errors.add(:route_params, :invalid)
  end
end
