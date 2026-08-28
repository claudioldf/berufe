# frozen_string_literal: true

class State < ApplicationRecord
  self.primary_key = :code

  has_many :cities, foreign_key: :state_code, inverse_of: :state, dependent: :restrict_with_exception

  scope :ordered, -> { order(:name, :code) }

  validates :code, presence: true, uniqueness: true, format: {with: /\A\d{2}\z/}
  validates :abbreviation, presence: true, uniqueness: true, format: {with: /\A[A-Z]{2}\z/}
  validates :name, presence: true, uniqueness: {case_sensitive: false}
  validate :code_is_immutable, on: :update

  private

  def code_is_immutable
    errors.add(:code, :readonly) if will_save_change_to_code?
  end
end
