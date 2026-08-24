# frozen_string_literal: true

class LegalRetentionRecord < ApplicationRecord
  RECORD_TYPES = %w[
    legal_acceptance recommendation_consent quote_acceptance referral_attestation moderation_event
  ].freeze

  validates :subject_digest, format: {with: /\A[0-9a-f]{64}\z/}
  validates :record_type, inclusion: {in: RECORD_TYPES}
  validates :occurred_at, :retained_until, presence: true
  validate :metadata_is_an_object

  private

  def metadata_is_an_object
    errors.add(:metadata, :invalid) unless metadata.is_a?(Hash)
  end
end
