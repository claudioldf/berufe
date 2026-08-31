# frozen_string_literal: true

class CustomerRecommendation < ApplicationRecord
  DELIVERY_CHANNELS = %w[email whatsapp].freeze

  belongs_to :service_job
  belongs_to :customer

  scope :publication_authorized, -> { where(publication_withdrawn_at: nil) }
  scope :publicly_visible, -> { publication_authorized.where(hidden_by_professional_at: nil) }
  scope :hidden_by_professional, -> { where.not(hidden_by_professional_at: nil) }

  validates :display_name, length: {in: 1..80}
  validates :recommendation_text, length: {in: 1..700}
  validates :email_fingerprint, format: {with: /\A[0-9a-f]{64}\z/}, allow_nil: true
  validates :delivery_channel, inclusion: {in: DELIVERY_CHANNELS}
  validates :service_confirmed_at, :publication_authorized_at, :submitted_at,
    presence: true
  validates :privacy_notice_version, presence: true
  validates :hidden_reason, length: {in: 1..700}, allow_nil: true
  validate :customer_matches_service_job
  validate :email_verification_matches_channel
  validate :hidden_reason_requires_hidden

  before_validation :normalize_text

  def email_channel?
    delivery_channel == "email"
  end

  def whatsapp_channel?
    delivery_channel == "whatsapp"
  end

  def hidden_by_professional?
    hidden_by_professional_at.present?
  end

  private

  def normalize_text
    self.display_name = display_name.to_s.squish
    self.recommendation_text = recommendation_text.to_s.squish
    self.hidden_reason = hidden_reason.to_s.squish.presence
  end

  def customer_matches_service_job
    return unless customer && service_job
    return if service_job.quote.customer_id == customer_id

    errors.add(:customer, :invalid)
  end

  def email_verification_matches_channel
    if email_channel?
      errors.add(:email_fingerprint, :blank) if email_fingerprint.blank?
      errors.add(:email_verified_at, :blank) if email_verified_at.blank?
    else
      errors.add(:email_fingerprint, :invalid) if email_fingerprint.present?
      errors.add(:email_verified_at, :invalid) if email_verified_at.present?
    end
  end

  def hidden_reason_requires_hidden
    errors.add(:hidden_reason, :invalid) if hidden_reason.present? && !hidden_by_professional?
  end
end
