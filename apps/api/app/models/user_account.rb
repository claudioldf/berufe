# frozen_string_literal: true

class UserAccount < ApplicationRecord
  ROLES = %w[admin professional].freeze
  STATUSES = %w[active suspended].freeze
  BRAZILIAN_MOBILE_PATTERN = /\A\+55[1-9][1-9]9\d{8}\z/
  ADMIN_PASSWORD_MINIMUM_LENGTH = 8
  ADMIN_PASSWORD_MAXIMUM_BYTES = 72

  has_many :application_sessions, dependent: :destroy
  has_many :impersonating_application_sessions,
    class_name: "ApplicationSession",
    foreign_key: :impersonated_user_account_id,
    dependent: :nullify,
    inverse_of: :impersonated_user_account
  has_many :admin_access_events, foreign_key: :admin_user_id, dependent: :restrict_with_exception,
    inverse_of: :admin_user
  has_many :catalog_change_events, foreign_key: :admin_user_id, dependent: :restrict_with_exception,
    inverse_of: :admin_user
  has_many :moderation_actions, foreign_key: :admin_user_id, dependent: :restrict_with_exception,
    inverse_of: :admin_user
  has_many :notifications,
    foreign_key: :recipient_user_account_id,
    dependent: :delete_all,
    inverse_of: :recipient_user_account
  has_many :verification_file_access_events, foreign_key: :admin_user_id, dependent: :restrict_with_exception,
    inverse_of: :admin_user
  has_one :professional_profile, dependent: :destroy
  has_secure_password validations: false

  before_validation :normalize_email

  validates :phone_e164, format: {with: BRAZILIAN_MOBILE_PATTERN}, uniqueness: true, if: :professional?
  validates :phone_e164, absence: true, if: :admin?
  validates :email, absence: true, if: :professional?
  validates :email, presence: true, uniqueness: true,
    format: {with: URI::MailTo::EMAIL_REGEXP}, if: :admin?
  validates :password_digest, presence: true, if: :admin?
  validates :password, confirmation: true, if: -> { admin? && password.present? }
  validates :role, inclusion: {in: ROLES}
  validates :status, inclusion: {in: STATUSES}
  validate :admin_password_is_strong, if: -> { admin? && password.present? }
  validate :legal_acceptance_is_complete
  validate :registration_requires_phone_verification

  def admin?
    role == "admin"
  end

  def professional?
    role == "professional"
  end

  def active?
    status == "active"
  end

  def registration_completed?(professional_profile_present: professional_profile.present?)
    registered? &&
      terms_accepted_at.present? &&
      terms_version == LegalDocumentVersions::TERMS &&
      privacy_notice_version == LegalDocumentVersions::PRIVACY_NOTICE &&
      professional_profile_present
  end

  def registered?
    professional? && registered_at.present?
  end

  def phone_verified?
    professional? && phone_verified_at.present?
  end

  # The single source of truth for whether an administrator may temporarily manage this
  # account's operational workspace (see Admin::ProfessionalImpersonation).
  def impersonatable?(professional_profile_present: professional_profile.present?)
    professional? && active? && phone_verified? &&
      registration_completed?(professional_profile_present:)
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

  def normalize_email
    self.email = AdminEmail.normalize(email)
  end

  def admin_password_is_strong
    if password.length < ADMIN_PASSWORD_MINIMUM_LENGTH
      errors.add(:password, :too_short, count: ADMIN_PASSWORD_MINIMUM_LENGTH)
    end
    if password.bytesize > ADMIN_PASSWORD_MAXIMUM_BYTES
      errors.add(:password, :too_long, count: ADMIN_PASSWORD_MAXIMUM_BYTES)
    end
  end

  def legal_acceptance_is_complete
    acceptance_values = [terms_accepted_at, terms_version, privacy_notice_version]
    return if acceptance_values.all?(&:nil?) || acceptance_values.all?(&:present?)

    errors.add(:terms_accepted_at, :invalid)
  end

  def registration_requires_phone_verification
    return if registered_at.blank? || phone_verified_at.present?

    errors.add(:registered_at, :invalid)
  end
end
