# frozen_string_literal: true

class ModerationMediaAccessEvent < ApplicationRecord
  TARGET_TYPES = %w[profile_photo portfolio_item].freeze

  belongs_to :admin_user, class_name: "UserAccount", inverse_of: :moderation_media_access_events

  validates :target_type, inclusion: {in: TARGET_TYPES}
  validates :target_id, presence: true
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
