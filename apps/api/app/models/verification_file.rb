# frozen_string_literal: true

class VerificationFile < ApplicationRecord
  belongs_to :verification_request
  belongs_to :media_upload

  validates :private_key, presence: true, uniqueness: true
  validates :content_type, inclusion: {in: MediaUpload::SUPPORTED_CONTENT_TYPES}
  validates :byte_size, numericality: {only_integer: true, greater_than: 0}
  validates :width, :height, numericality: {only_integer: true, greater_than: 0}
  validates :uploaded_at, presence: true
end
