# frozen_string_literal: true

class ServiceJob < ApplicationRecord
  STATUSES = %w[approved completion_requested completion_issue completed cancelled].freeze

  belongs_to :quote
  has_one :customer_recommendation_request, dependent: :restrict_with_exception
  has_one :customer_recommendation, dependent: :restrict_with_exception

  validates :status, inclusion: {in: STATUSES}
  validates :completion_issue_message, length: {in: 1..700}, allow_nil: true
  validates :cancellation_reason, length: {in: 1..700}, allow_nil: true

  before_validation :normalize_text

  delegate :professional, :customer, to: :quote

  STATUSES.each do |known_status|
    define_method("#{known_status}?") { status == known_status }
  end

  private

  def normalize_text
    self.completion_issue_message = completion_issue_message.to_s.squish.presence
    self.cancellation_reason = cancellation_reason.to_s.squish.presence
  end
end
