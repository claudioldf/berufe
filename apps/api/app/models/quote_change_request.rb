# frozen_string_literal: true

class QuoteChangeRequest < ApplicationRecord
  belongs_to :quote, inverse_of: :quote_change_requests

  attr_readonly :quote_id, :requested_revision, :message, :requested_at

  validates :requested_revision,
    numericality: {only_integer: true, greater_than_or_equal_to: 0},
    uniqueness: {scope: :quote_id}
  validates :message, length: {in: 1..700}
  validates :requested_at, presence: true

  before_validation :normalize_message

  private

  def normalize_message
    self.message = message.to_s.squish
  end
end
