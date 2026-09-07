# frozen_string_literal: true

class ServiceAdjustmentItem < ApplicationRecord
  KINDS = %w[additional_service material_charge material_reimbursement credit].freeze

  belongs_to :service_adjustment, inverse_of: :service_adjustment_items
  has_one :service_adjustment_receipt, dependent: :destroy

  validates :kind, inclusion: {in: KINDS}
  validates :description, length: {in: 1..160}
  validates :quantity, numericality: {greater_than: 0}
  validates :unit, length: {in: 1..20}
  validates :unit_price, numericality: {greater_than_or_equal_to: 0}
  validates :line_total, numericality: true
  validates :sort_order,
    numericality: {only_integer: true, greater_than_or_equal_to: 0},
    uniqueness: {scope: :service_adjustment_id}

  before_validation :normalize_text
  before_validation :recalculate_line_total

  def credit?
    kind == "credit"
  end

  def reimbursement?
    kind == "material_reimbursement"
  end

  def recalculate_line_total
    amount = BigDecimal(quantity.to_s) * BigDecimal(unit_price.to_s)
    amount = -amount if credit?
    self.line_total = amount.round(ServiceAdjustment::MONEY_SCALE, BigDecimal::ROUND_HALF_UP)
  rescue ArgumentError
    self.line_total = nil
  end

  private

  def normalize_text
    self.description = description.to_s.squish
    self.unit = unit.to_s.squish
  end
end
