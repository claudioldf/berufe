# frozen_string_literal: true

class VerificationRequest < ApplicationRecord
  TYPES = %w[identity].freeze
  STATUSES = %w[pending_review approved rejected expired].freeze

  belongs_to :professional_profile
  belongs_to :reviewed_by_user_account, class_name: "UserAccount", optional: true
  has_one :verification_file, dependent: :destroy

  scope :identity, -> { where(verification_type: "identity") }
  scope :newest_first, -> { order(submitted_at: :desc, id: :desc) }

  validates :verification_type, inclusion: {in: TYPES}
  validates :status, inclusion: {in: STATUSES}
  validates :submitted_at, presence: true

  STATUSES.each do |known_status|
    define_method("#{known_status}?") { status == known_status }
  end
end
