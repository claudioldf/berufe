# frozen_string_literal: true

class Service < ApplicationRecord
  belongs_to :category, class_name: "ServiceCategory", inverse_of: :services

  scope :active, -> { where(is_active: true) }
  scope :ordered, -> { order(:sort_order, :slug) }
  scope :publicly_active, -> { active.joins(:category).merge(ServiceCategory.active) }

  validates :name, :slug, :icon, :description, presence: true
  validates :slug, uniqueness: true, format: {with: /\A[a-z0-9]+(?:-[a-z0-9]+)*\z/}
  validates :sort_order, numericality: {only_integer: true, greater_than_or_equal_to: 0}
  validates :is_active, inclusion: {in: [true, false]}
  validate :aliases_are_present_strings
  validate :slug_is_immutable, on: :update

  private

  def aliases_are_present_strings
    return if aliases.is_a?(Array) && aliases.all? { |value| value.is_a?(String) && value.present? }

    errors.add(:aliases, :invalid)
  end

  def slug_is_immutable
    errors.add(:slug, :readonly) if will_save_change_to_slug?
  end
end
