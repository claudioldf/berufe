# frozen_string_literal: true

class UserAccount < ApplicationRecord
  ROLES = %w[admin professional].freeze
  STATUSES = %w[active suspended].freeze
  BRAZILIAN_MOBILE_PATTERN = /\A\+55[1-9][1-9]9\d{8}\z/

  has_many :application_sessions, dependent: :restrict_with_exception

  validates :phone_e164, format: {with: BRAZILIAN_MOBILE_PATTERN}, uniqueness: true
  validates :role, inclusion: {in: ROLES}
  validates :status, inclusion: {in: STATUSES}

  def admin?
    role == "admin"
  end
end
