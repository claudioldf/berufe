# frozen_string_literal: true

class CustomerRecommendation < ApplicationRecord
  belongs_to :service_job
  belongs_to :customer

  validates :display_name, length: {in: 1..80}
  validates :recommendation_text, length: {in: 1..700}
  validates :email_fingerprint, format: {with: /\A[0-9a-f]{64}\z/}
  validates :email_verified_at, :service_confirmed_at, :publication_authorized_at, :submitted_at,
    presence: true
  validate :customer_matches_service_job

  before_validation :normalize_text

  private

  def normalize_text
    self.display_name = display_name.to_s.squish
    self.recommendation_text = recommendation_text.to_s.squish
  end

  def customer_matches_service_job
    return unless customer && service_job
    return if service_job.quote.customer_id == customer_id

    errors.add(:customer, :invalid)
  end
end
