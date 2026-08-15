# frozen_string_literal: true

class UserAccount < ApplicationRecord
  ROLES = %w[admin professional].freeze
  STATUSES = %w[active suspended].freeze
  BRAZILIAN_MOBILE_PATTERN = /\A\+55[1-9][1-9]9\d{8}\z/

  has_many :application_sessions, dependent: :restrict_with_exception
  has_one :professional_profile, dependent: :restrict_with_exception

  validates :phone_e164, format: {with: BRAZILIAN_MOBILE_PATTERN}, uniqueness: true
  validates :role, inclusion: {in: ROLES}
  validates :status, inclusion: {in: STATUSES}
  validate :legal_acceptance_is_complete

  def admin?
    role == "admin"
  end

  def professional?
    role == "professional"
  end

  def active?
    status == "active"
  end

  def registration_completed?
    professional? &&
      terms_accepted_at.present? &&
      terms_version.present? &&
      privacy_notice_version.present? &&
      professional_profile.present?
  end

  def revoke_all_sessions!(now: Time.current)
    application_sessions.where(revoked_at: nil).update_all(revoked_at: now, updated_at: now)
  end

  def suspend!(now: Time.current)
    with_lock do
      update!(status: "suspended")
      revoke_all_sessions!(now:)
    end
  end

  private

  def legal_acceptance_is_complete
    acceptance_values = [terms_accepted_at, terms_version, privacy_notice_version]
    return if acceptance_values.all?(&:nil?) || acceptance_values.all?(&:present?)

    errors.add(:terms_accepted_at, :invalid)
  end
end
