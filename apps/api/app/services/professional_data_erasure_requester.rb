# frozen_string_literal: true

class ProfessionalDataErasureRequester
  class NotFound < StandardError; end
  class VerificationRequired < StandardError; end

  RECENT_VERIFICATION_WINDOW = 30.minutes
  AUDIT_RETENTION = 5.years

  def call(phone_e164:, ticket_reference:, now: Time.current)
    phone = BrazilianPhoneNumber.normalize(phone_e164)
    account = UserAccount.includes(:professional_profile).find_by(phone_e164: phone, role: "professional")
    raise NotFound unless account&.professional_profile
    raise VerificationRequired unless recently_verified?(account, now:)

    request_record = nil
    ApplicationRecord.transaction do
      account.lock!
      request_record = DataErasureRequest.find_by(
        target_user_account_id: account.id,
        status: %w[requested processing failed]
      )
      next if request_record

      account.update!(status: "suspended")
      account.professional_profile.update_columns(profile_status: "suspended", updated_at: now)
      account.revoke_all_sessions!(now:)
      revoke_shared_links!(account.professional_profile, now:)

      request_record = DataErasureRequest.create!(
        target_user_account_id: account.id,
        subject_digest: PrivacySubjectDigest.call(phone),
        ticket_reference:,
        status: "requested",
        verification_method: "recent_sms_otp",
        requested_at: now,
        verified_at: now,
        unpublished_at: now,
        retained_until: now + AUDIT_RETENTION
      )
    end

    ProfessionalDataErasureJob.perform_later(request_record.id)
    request_record
  rescue BrazilianPhoneNumber::Invalid
    raise NotFound
  end

  private

  def recently_verified?(account, now:)
    account.application_sessions.where(authentication_method: "sms_otp")
      .where(authenticated_at: (now - RECENT_VERIFICATION_WINDOW)..now)
      .exists?
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
