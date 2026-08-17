# frozen_string_literal: true

class CatalogChangeEvent < ApplicationRecord
  ACTIONS = %w[activated created deactivated reordered updated].freeze
  CATALOG_TYPES = %w[neighborhood service].freeze

  belongs_to :admin_user, class_name: "UserAccount", inverse_of: :catalog_change_events

  validates :action, inclusion: {in: ACTIONS}
  validates :catalog_type, inclusion: {in: CATALOG_TYPES}
  validates :target_identifier, presence: true
  validates :change_data, presence: true
  validates :request_id, format: {with: RequestIdSanitizer::VALID_REQUEST_ID}
  validate :change_data_is_an_object
  validate :user_is_an_admin

  def readonly?
    persisted?
  end

  private

  def change_data_is_an_object
    errors.add(:change_data, :invalid) unless change_data.is_a?(Hash)
  end

  def user_is_an_admin
    errors.add(:admin_user, :invalid) unless admin_user&.admin?
  end
end
