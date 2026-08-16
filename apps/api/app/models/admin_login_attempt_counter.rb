# frozen_string_literal: true

class AdminLoginAttemptCounter < ApplicationRecord
  SCOPES = %w[email ip].freeze

  validates :scope, inclusion: {in: SCOPES}
  validates :subject_digest, format: {with: /\A[0-9a-f]{64}\z/}
  validates :window_started_at, presence: true
  validates :attempt_count, numericality: {only_integer: true, greater_than_or_equal_to: 0}
end
