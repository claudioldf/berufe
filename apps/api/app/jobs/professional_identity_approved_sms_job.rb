# frozen_string_literal: true

class ProfessionalIdentityApprovedSmsJob < ApplicationJob
  queue_as :default
  self.enqueue_after_transaction_commit = true

  retry_on SmsOtp::ProviderUnavailable, SmsOtp::RateLimited, wait: :polynomially_longer, attempts: 5
  discard_on SmsOtp::DeliveryRejected

  def perform(verification_request_id, client: SmsOtpClient.build)
    request = VerificationRequest.includes(professional_profile: :user_account).find_by(id: verification_request_id)
    return unless request&.status == "approved"

    profile = request.professional_profile
    account = profile.user_account
    return unless account.active? && account.phone_e164.present?

    client.send_text(
      phone: account.phone_e164,
      text: "Berufe: a equipe confirmou sua identidade. Veja seu perfil público: #{IdentityApprovalLink.profile_url(profile)}"
    )
  rescue SmsOtp::Error => error
    Rails.error.report(error, context: {verification_request_id:})
    raise
  end
end
