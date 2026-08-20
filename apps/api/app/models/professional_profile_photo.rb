# frozen_string_literal: true

class ProfessionalProfilePhoto < ApplicationRecord
  STATUSES = %w[pending_review approved rejected hidden superseded].freeze

  belongs_to :professional_profile
  belongs_to :media_upload

  scope :publicly_visible, -> {
    joins(:professional_profile)
      .merge(ProfessionalProfile.publicly_eligible)
      .where(status: %w[pending_review approved])
      .where("professional_profiles.published_photo_id = professional_profile_photos.id")
  }

  validates :status, inclusion: {in: STATUSES}
  validates :private_key, presence: true, uniqueness: true
  validates :public_key, uniqueness: true, allow_nil: true
  validates :content_type, inclusion: {in: %w[image/jpeg]}
  validates :byte_size, numericality: {only_integer: true, greater_than: 0}
  validates :width, numericality: {only_integer: true, in: 1..1024}
  validates :height, numericality: {only_integer: true, in: 1..1536}
  validates :submitted_at, presence: true

  STATUSES.each do |known_status|
    define_method("#{known_status}?") { status == known_status }
  end
end
