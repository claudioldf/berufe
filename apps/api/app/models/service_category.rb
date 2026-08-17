# frozen_string_literal: true

class ServiceCategory < ApplicationRecord
  has_many :services, foreign_key: :category_id, inverse_of: :category, dependent: :restrict_with_exception

  scope :active, -> { where(is_active: true) }
  scope :ordered, -> { order(:sort_order, :slug) }

  validates :name, :slug, :icon, presence: true
  validates :name, uniqueness: {case_sensitive: false, conditions: -> { where(is_active: true) }}, if: :is_active?
  validates :slug, uniqueness: true, format: {with: /\A[a-z0-9]+(?:-[a-z0-9]+)*\z/}
  validates :sort_order, numericality: {only_integer: true, greater_than_or_equal_to: 0}
  validates :is_active, inclusion: {in: [true, false]}
  validate :slug_is_immutable, on: :update

  private

  def slug_is_immutable
    errors.add(:slug, :readonly) if will_save_change_to_slug?
  end
end
