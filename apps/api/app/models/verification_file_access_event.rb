# frozen_string_literal: true

class VerificationFileAccessEvent < ApplicationRecord
  ACTIONS = %w[viewed].freeze

  belongs_to :verification_file
  belongs_to :admin_user, class_name: "UserAccount", inverse_of: :verification_file_access_events

  validates :action, inclusion: {in: ACTIONS}
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
