# frozen_string_literal: true

class LlmSearchAnalysis < ApplicationRecord
  validates :cache_key_digest, :expression_digest, :prompt_digest,
    format: {with: /\A[0-9a-f]{64}\z/}
  validates :adapter, :model, :parsed_result, :expires_at, presence: true
  validates :raw_response, presence: true, allow_nil: true
  validates :cache_hit_count, numericality: {only_integer: true, greater_than_or_equal_to: 0}

  scope :available, ->(now = Time.current) { where(expires_at: now..) }
end
