# frozen_string_literal: true

class QuoteItem < ApplicationRecord
  belongs_to :quote, inverse_of: :quote_items

  validates :description, length: {in: 1..160}
  validates :quantity, numericality: {greater_than: 0}
  validates :unit, length: {in: 1..20}
  validates :unit_price, :line_total, numericality: {greater_than_or_equal_to: 0}
  validates :sort_order,
    numericality: {only_integer: true, greater_than_or_equal_to: 0},
    uniqueness: {scope: :quote_id}

  before_validation :normalize_text
  before_validation :recalculate_line_total

  def recalculate_line_total
    amount = BigDecimal(quantity.to_s) * BigDecimal(unit_price.to_s)
    self.line_total = amount.round(Quote::MONEY_SCALE, BigDecimal::ROUND_HALF_UP)
  rescue ArgumentError
    self.line_total = nil
  end

  private

  def normalize_text
    self.description = description.to_s.squish
    self.unit = unit.to_s.squish
  end
end
