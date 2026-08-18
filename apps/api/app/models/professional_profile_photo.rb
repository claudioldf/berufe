# frozen_string_literal: true

class ProfessionalProfilePhoto < ApplicationRecord
  STATUSES = %w[pending_review approved rejected hidden superseded].freeze

  belongs_to :professional_profile
  belongs_to :media_upload

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
