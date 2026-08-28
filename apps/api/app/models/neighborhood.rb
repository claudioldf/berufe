# frozen_string_literal: true

class Neighborhood < ApplicationRecord
  self.primary_key = :code

  belongs_to :city, foreign_key: :city_code, inverse_of: :neighborhoods

  scope :active, -> { all }
  scope :ordered, -> { order(:name, :code) }

  validates :code, :city_code, :name, presence: true
  validates :code, uniqueness: true, format: {with: /\A\d{10}\z/}
  validate :code_is_immutable, on: :update

  delegate :state, to: :city

  def state_code
    state.abbreviation
  end

  private

  def code_is_immutable
    errors.add(:code, :readonly) if will_save_change_to_code?
  end
end
