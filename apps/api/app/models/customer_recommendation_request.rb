# frozen_string_literal: true

class CustomerRecommendationRequest < ApplicationRecord
  STATUSES = %w[open completed expired].freeze
  DELIVERY_CHANNELS = %w[email whatsapp].freeze

  belongs_to :service_job

  validates :token_hash, format: {with: /\A[0-9a-f]{64}\z/}, uniqueness: true
  validates :email_fingerprint, format: {with: /\A[0-9a-f]{64}\z/}, allow_nil: true
  validates :status, inclusion: {in: STATUSES}
  validates :delivery_channel, inclusion: {in: DELIVERY_CHANNELS}
  validates :expires_at, presence: true
  validate :email_fingerprint_matches_channel

  def email_channel?
    delivery_channel == "email"
  end

  def whatsapp_channel?
    delivery_channel == "whatsapp"
  end

  STATUSES.each do |known_status|
    define_method("#{known_status}?") { status == known_status }
  end

  def open_at?(time = Time.current)
    status == "open" && expires_at > time
  end

  private

  def email_fingerprint_matches_channel
    if email_channel? && email_fingerprint.blank?
      errors.add(:email_fingerprint, :blank)
    elsif whatsapp_channel? && email_fingerprint.present?
      errors.add(:email_fingerprint, :invalid)
    end
  end
end
