# frozen_string_literal: true

class DataErasureRequest < ApplicationRecord
  STATUSES = %w[requested processing failed completed].freeze
  VERIFICATION_METHODS = %w[recent_sms_otp].freeze

  validates :target_user_account_id, :requested_at, :verified_at, :unpublished_at, :retained_until,
    presence: true
  validates :subject_digest, format: {with: /\A[0-9a-f]{64}\z/}
  validates :ticket_reference, format: {with: /\A[A-Za-z0-9._\/-]{1,100}\z/}
  validates :status, inclusion: {in: STATUSES}
  validates :verification_method, inclusion: {in: VERIFICATION_METHODS}
end
