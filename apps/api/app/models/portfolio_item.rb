# frozen_string_literal: true

class PortfolioItem < ApplicationRecord
  belongs_to :professional_profile
  belongs_to :media_upload
  belongs_to :service

  scope :active, -> { where(deleted_at: nil) }
  scope :publicly_visible, -> { active }
  scope :newest_first, -> { order(submitted_at: :desc, id: :desc) }

  validates :title, length: {in: 1..80}
  validates :description, length: {maximum: 300}, allow_nil: true
  validates :private_key, presence: true, uniqueness: true
  validates :content_type, inclusion: {in: MediaUpload::SUPPORTED_CONTENT_TYPES}
  validates :byte_size, numericality: {only_integer: true, greater_than: 0}
  validates :width, :height, numericality: {only_integer: true, greater_than: 0}
  validates :submitted_at, presence: true
end
