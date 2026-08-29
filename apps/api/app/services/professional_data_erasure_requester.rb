# frozen_string_literal: true

class ProfessionalDataErasureRequester
  class NotFound < StandardError; end
  class VerificationRequired < StandardError; end

  RECENT_VERIFICATION_WINDOW = 30.minutes
  AUDIT_RETENTION = 5.years

  def call(
    phone_e164:,
    ticket_reference:,
    now: Time.current,
    verification_session: nil,
    request_source: "support",
    confirmation_version: nil,
    issue_status_token: false
  )
    phone = BrazilianPhoneNumber.normalize(phone_e164)
    account = UserAccount.includes(:professional_profile).find_by(phone_e164: phone, role: "professional")
    raise NotFound unless account&.professional_profile
    raise VerificationRequired unless recently_verified?(account, verification_session:, now:)

    request_record = nil
    ApplicationRecord.transaction do
      account.lock!
      request_record = DataErasureRequest.find_by(
        target_user_account_id: account.id,
        status: %w[requested processing failed]
      )
      if request_record
        attach_status_token!(request_record) if issue_status_token
        next
      end

      account.update!(status: "suspended")
      account.professional_profile.update_columns(profile_status: "suspended", updated_at: now)
      account.revoke_all_sessions!(now:)
      revoke_shared_links!(account.professional_profile, now:)

      status_token = DataErasureStatusToken.issue if issue_status_token
      request_record = DataErasureRequest.create!(
        target_user_account_id: account.id,
        subject_digest: PrivacySubjectDigest.call(phone),
        ticket_reference:,
        status: "requested",
        verification_method: "recent_sms_otp",
        request_source:,
        confirmation_version:,
        status_token_hash: status_token && DataErasureStatusToken.digest(status_token),
        status_token_ciphertext: status_token && DataErasureStatusToken.encrypt(status_token),
        requested_at: now,
        verified_at: now,
        unpublished_at: now,
        retained_until: now + AUDIT_RETENTION
      )
      request_record.status_token = status_token
    end

    enqueue_erasure(request_record, now:)
    request_record
  rescue BrazilianPhoneNumber::Invalid
    raise NotFound
  end

  private

  def enqueue_erasure(request_record, now:)
    ProfessionalDataErasureJob.perform_later(request_record.id)
  rescue => error
    request_record.update_columns(status: "failed", failure_code: "enqueue_error", updated_at: now)
    Rails.error.report(error, context: {data_erasure_request_id: request_record.id})
  end

  def recently_verified?(account, verification_session:, now:)
    if verification_session
      return verification_session.user_account_id == account.id &&
          verification_session.authentication_method == "sms_otp" &&
          verification_session.authenticated_at.between?(now - RECENT_VERIFICATION_WINDOW, now)
    end

    account.application_sessions.where(authentication_method: "sms_otp")
      .where(authenticated_at: (now - RECENT_VERIFICATION_WINDOW)..now)
      .exists?
  end

  def attach_status_token!(request_record)
    token = DataErasureStatusToken.decrypt(request_record.status_token_ciphertext)
    unless DataErasureStatusToken.valid?(token)
      token = DataErasureStatusToken.issue
      request_record.update!(
        status_token_hash: DataErasureStatusToken.digest(token),
        status_token_ciphertext: DataErasureStatusToken.encrypt(token)
      )
    end
    request_record.status_token = token
  end

  def revoke_shared_links!(profile, now:)
    profile.quotes.where.not(status: "draft").find_each do |quote|
      replacement = QuoteShareToken.issue
      quote.update_columns(
        share_token_hash: QuoteShareToken.digest(replacement),
        share_token_ciphertext: QuoteShareToken.encrypt(replacement),
        updated_at: now
      )
    end

    CustomerRecommendationRequest
      .joins(service_job: :quote)
      .where(quotes: {professional_id: profile.id}, status: "open")
      .update_all(status: "expired", token_ciphertext: nil, updated_at: now)
  end
end
