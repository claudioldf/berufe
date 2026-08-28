# frozen_string_literal: true

class City < ApplicationRecord
  self.primary_key = :code

  belongs_to :state, foreign_key: :state_code, inverse_of: :cities
  has_many :neighborhoods, foreign_key: :city_code, inverse_of: :city, dependent: :restrict_with_exception

  scope :ordered, -> { order(:name, :code) }

  validates :code, presence: true, uniqueness: true, format: {with: /\A\d{7}\z/}
  validates :name, presence: true, uniqueness: {scope: :state_code, case_sensitive: false}
  validates :slug, presence: true,
    uniqueness: {scope: :state_code},
    format: {with: /\A[a-z0-9]+(?:-[a-z0-9]+)*\z/}
  validate :code_is_immutable, on: :update

  private

  def code_is_immutable
    errors.add(:code, :readonly) if will_save_change_to_code?
  end
end
