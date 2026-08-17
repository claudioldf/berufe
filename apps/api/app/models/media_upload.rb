# frozen_string_literal: true

class MediaUpload < ApplicationRecord
  PURPOSES = %w[profile_photo portfolio_image verification_identity].freeze
  STATES = %w[authorized uploaded processing processed failed attached expired].freeze
  SUPPORTED_CONTENT_TYPES = %w[image/jpeg image/png].freeze
  MAX_BYTE_SIZE = 10.megabytes
  MAX_PIXELS = 25_000_000
  AUTHORIZATION_TTL = 10.minutes
  RETRYABLE_FAILURE_CODES = %w[storage_unavailable processing_unavailable].freeze

  belongs_to :professional_profile

  validates :purpose, inclusion: {in: PURPOSES}
  validates :state, inclusion: {in: STATES}
  validates :declared_content_type, inclusion: {in: SUPPORTED_CONTENT_TYPES}
  validates :declared_byte_size, numericality: {only_integer: true, in: 1..MAX_BYTE_SIZE}
  validates :quarantine_key, presence: true, uniqueness: true
  validates :sanitized_key, uniqueness: true, allow_nil: true
  validates :sanitized_content_type, inclusion: {in: SUPPORTED_CONTENT_TYPES}, allow_nil: true
  validates :authorization_expires_at, presence: true
  validates :processing_attempts, numericality: {only_integer: true, greater_than_or_equal_to: 0}

  def authorization_expired?(now = Time.current)
    authorization_expires_at <= now
  end

  def retryable?
    failed? && failure_code.in?(RETRYABLE_FAILURE_CODES)
  end

  STATES.each do |known_state|
    define_method("#{known_state}?") { state == known_state }
  end
end
