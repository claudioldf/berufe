# frozen_string_literal: true

class CustomerRecommendationRequest < ApplicationRecord
  STATUSES = %w[open completed expired].freeze

  belongs_to :service_job

  validates :token_hash, format: {with: /\A[0-9a-f]{64}\z/}, uniqueness: true
  validates :email_fingerprint, format: {with: /\A[0-9a-f]{64}\z/}
  validates :status, inclusion: {in: STATUSES}
  validates :expires_at, presence: true

  STATUSES.each do |known_status|
    define_method("#{known_status}?") { status == known_status }
  end

  def open_at?(time = Time.current)
    status == "open" && expires_at > time
  end
end
