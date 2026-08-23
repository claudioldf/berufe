# frozen_string_literal: true

class AdminAccountManager
  def provision!(email:, password:, password_confirmation:, operator_identifier:, request_id: nil, now: Time.current)
    operator_identifier = normalized_operator_identifier(operator_identifier)

    UserAccount.transaction do
      account = UserAccount.create!(
        email:,
        password:,
        password_confirmation:,
        role: "admin",
        status: "active"
      )
      record_event!(account:, action: "provisioned", operator_identifier:, request_id:, now:)
      account
    end
  end

  def reset_password!(email:, password:, password_confirmation:, operator_identifier:, request_id: nil, now: Time.current)
    operator_identifier = normalized_operator_identifier(operator_identifier)

    UserAccount.transaction do
      account = UserAccount.lock.find_by!(email: AdminEmail.normalize(email), role: "admin")
      account.update!(password:, password_confirmation:)
      account.revoke_all_sessions!(now:)
      record_event!(account:, action: "password_reset", operator_identifier:, request_id:, now:)
      account
    end
  end

  private

  def normalized_operator_identifier(value)
    value.to_s.strip.presence || raise(ArgumentError, "operator_identifier is required")
  end

  def record_event!(account:, action:, operator_identifier:, request_id:, now:)
    AdminAccessEvent.create!(
      admin_user: account,
      action:,
      operator_identifier:,
      request_id: normalized_request_id(request_id),
      created_at: now
    )
  end

  def normalized_request_id(value)
    request_id = value.to_s.presence || SecureRandom.uuid
    return request_id if RequestIdSanitizer::VALID_REQUEST_ID.match?(request_id)

    raise ArgumentError, "request_id is invalid"
  end
end
