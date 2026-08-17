# frozen_string_literal: true

class AdminSeed
  DEFAULT_EMAIL = "admin@berufe.com.br"
  DEFAULT_PASSWORD = "@Qwer1234"
  OPERATOR_IDENTIFIER = "database-seed"
  REQUEST_ID = "admin-seed"

  def call
    if Rails.env.production?
      Rails.logger.warn("Administrator seed skipped in production.")
      return
    end

    email = ENV["ADMIN_AUTH_EMAIL"].presence || DEFAULT_EMAIL
    existing_account = UserAccount.find_by(email: AdminEmail.normalize(email), role: "admin")
    return existing_account if existing_account

    password = ENV["ADMIN_AUTH_PASSWORD"].presence || DEFAULT_PASSWORD
    UserAccount.transaction do
      account = UserAccount.create!(
        email:,
        password:,
        password_confirmation: password,
        role: "admin",
        status: "active"
      )
      AdminAccessEvent.create!(
        admin_user: account,
        action: "provisioned",
        operator_identifier: OPERATOR_IDENTIFIER,
        request_id: REQUEST_ID,
        created_at: Time.current
      )
      account
    end
  end
end
