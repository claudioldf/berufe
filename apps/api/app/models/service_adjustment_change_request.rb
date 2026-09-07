# frozen_string_literal: true

class ServiceAdjustmentChangeRequest < ApplicationRecord
  belongs_to :service_adjustment, inverse_of: :service_adjustment_change_requests

  attr_readonly :service_adjustment_id, :requested_revision, :message, :requested_at

  validates :requested_revision,
    numericality: {only_integer: true, greater_than_or_equal_to: 0},
    uniqueness: {scope: :service_adjustment_id}
  validates :message, length: {in: 1..700}
  validates :requested_at, presence: true

  before_validation { self.message = message.to_s.squish }
end
