# frozen_string_literal: true

class ModerationAction < ApplicationRecord
  TARGET_TYPES = %w[verification_request professional_profile].freeze
  ACTIONS = %w[approved rejected hidden restored].freeze
  TARGET_ACTIONS = {
    "verification_request" => %w[approved rejected],
    "professional_profile" => %w[hidden restored]
  }.freeze

  belongs_to :admin_user, class_name: "UserAccount", inverse_of: :moderation_actions

  validates :target_type, inclusion: {in: TARGET_TYPES}
  validates :target_id, presence: true
  validates :action, inclusion: {in: ACTIONS}
  validates :reason, length: {in: 10..500}, presence: true, if: -> { action.in?(%w[rejected hidden]) }
  validates :reason, absence: true, unless: -> { action.in?(%w[rejected hidden]) }
  validates :note, length: {maximum: 500}, allow_nil: true
  validates :request_id, format: {with: RequestIdSanitizer::VALID_REQUEST_ID}
  validate :action_matches_target
  validate :user_is_an_admin

  before_validation :normalize_text

  def readonly?
    persisted?
  end

  private

  def normalize_text
    self.reason = reason.to_s.squish.presence
    self.note = note.to_s.squish.presence
  end

  def user_is_an_admin
    errors.add(:admin_user, :invalid) unless admin_user&.admin?
  end

  def action_matches_target
    return if TARGET_ACTIONS.fetch(target_type, []).include?(action)

    errors.add(:action, :invalid)
  end
end
