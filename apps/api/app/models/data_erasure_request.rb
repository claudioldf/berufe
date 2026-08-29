# frozen_string_literal: true

class DataErasureRequest < ApplicationRecord
  STATUSES = %w[requested processing failed completed].freeze
  VERIFICATION_METHODS = %w[recent_sms_otp authenticated_session].freeze
  REQUEST_SOURCES = %w[support self_service].freeze
  SELF_SERVICE_CONFIRMATION_VERSION = "1.0"

  attr_accessor :status_token

  validates :target_user_account_id, presence: true, unless: :completed?
  validates :requested_at, :verified_at, :unpublished_at, :retained_until, presence: true
  validates :subject_digest, format: {with: /\A[0-9a-f]{64}\z/}
  validates :ticket_reference, format: {with: /\A[A-Za-z0-9._\/-]{1,100}\z/}
  validates :status, inclusion: {in: STATUSES}
  validates :verification_method, inclusion: {in: VERIFICATION_METHODS}
  validates :request_source, inclusion: {in: REQUEST_SOURCES}
  validates :status_token_hash, format: {with: /\A[0-9a-f]{64}\z/}, allow_nil: true
  validates :confirmation_version, presence: true, if: :self_service?
  validates :status_token_hash, :status_token_ciphertext, presence: true, if: :self_service?
  validate :status_token_pair_is_complete

  def completed?
    status == "completed"
  end

  def self_service?
    request_source == "self_service"
  end

  private

  def status_token_pair_is_complete
    return if status_token_hash.present? == status_token_ciphertext.present?

    errors.add(:status_token_hash, :invalid)
  end
end
