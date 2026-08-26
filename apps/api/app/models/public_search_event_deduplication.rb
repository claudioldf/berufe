# frozen_string_literal: true

class PublicSearchEventDeduplication < ApplicationRecord
  belongs_to :search_event

  validates :subject_digest, :query_digest, format: {with: /\A[0-9a-f]{64}\z/}
  validates :result_count, numericality: {only_integer: true, greater_than_or_equal_to: 0}
  validates :expires_at, presence: true
end
