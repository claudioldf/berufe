# frozen_string_literal: true

class ProfessionalProfilePhoto < ApplicationRecord
  belongs_to :professional_profile
  belongs_to :media_upload

  scope :active, -> { where(deleted_at: nil) }
  scope :publicly_visible, -> {
    joins(:professional_profile)
      .merge(ProfessionalProfile.publicly_eligible)
      .where(deleted_at: nil)
      .where("professional_profiles.profile_photo_id = professional_profile_photos.id")
  }

  validates :private_key, presence: true, uniqueness: true
  validates :content_type, inclusion: {in: %w[image/jpeg]}
  validates :byte_size, numericality: {only_integer: true, greater_than: 0}
  validates :width, numericality: {only_integer: true, in: 1..1024}
  validates :height, numericality: {only_integer: true, in: 1..1536}
  validates :submitted_at, presence: true
end
