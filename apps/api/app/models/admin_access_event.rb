# frozen_string_literal: true

class AdminAccessEvent < ApplicationRecord
  ACTIONS = %w[password_reset provisioned].freeze

  belongs_to :admin_user, class_name: "UserAccount", inverse_of: :admin_access_events

  validates :action, inclusion: {in: ACTIONS}
  validates :operator_identifier, presence: true
  validates :request_id, format: {with: RequestIdSanitizer::VALID_REQUEST_ID}
  validate :user_is_an_admin

  def readonly?
    persisted?
  end

  private

  def user_is_an_admin
    errors.add(:admin_user, :invalid) unless admin_user&.admin?
  end
end
