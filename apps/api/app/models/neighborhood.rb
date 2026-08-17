# frozen_string_literal: true

class Neighborhood < ApplicationRecord
  self.primary_key = :code

  scope :active, -> { where(is_active: true) }
  scope :ordered, -> { order(:sort_order, :code) }

  validates :code, :state_code, :city_code, :name, presence: true
  validates :code, :city_code, :name, length: {maximum: 80}
  validates :code, uniqueness: true, format: {with: /\A[a-z0-9]+(?:-[a-z0-9]+)*\z/}
  validates :state_code, inclusion: {in: ["SC"]}
  validates :city_code, inclusion: {in: ["Joinville"]}
  validates :sort_order, numericality: {only_integer: true, greater_than_or_equal_to: 0}
  validates :is_active, inclusion: {in: [true, false]}
  validate :code_is_immutable, on: :update

  private

  def code_is_immutable
    errors.add(:code, :readonly) if will_save_change_to_code?
  end
end
