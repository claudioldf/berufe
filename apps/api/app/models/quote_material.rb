# frozen_string_literal: true

class QuoteMaterial < ApplicationRecord
  belongs_to :quote, inverse_of: :quote_materials

  validates :description, length: {maximum: 160}
  validates :quantity, numericality: {greater_than_or_equal_to: 0}
  validates :unit, length: {maximum: 20}
  validates :sort_order,
    numericality: {only_integer: true, greater_than_or_equal_to: 0},
    uniqueness: {scope: :quote_id}
  with_options unless: :draft? do
    validates :description, presence: true
    validates :quantity, numericality: {greater_than: 0}
    validates :unit, presence: true
  end

  before_validation :normalize_text

  private

  def draft?
    quote&.draft?
  end

  def normalize_text
    self.description = description.to_s.squish
    self.unit = unit.to_s.squish
  end
end
