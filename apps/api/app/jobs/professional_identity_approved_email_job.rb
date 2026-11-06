# frozen_string_literal: true

class ProfessionalIdentityApprovedEmailJob < ApplicationJob
  queue_as :default
  self.enqueue_after_transaction_commit = true

  retry_on Berufe::MailDelivery::ProviderUnavailable, wait: :polynomially_longer, attempts: 5
  discard_on Berufe::MailDelivery::Rejected

  def perform(verification_request_id, mailer: ProfessionalIdentityApprovedMailer)
    request = VerificationRequest.includes(professional_profile: :user_account).find_by(id: verification_request_id)
    return unless request&.status == "approved"

    profile = request.professional_profile
    account = profile.user_account
    return unless account.active? && account.email.present?

    mail = mailer.with(
      email: account.email,
      display_name: profile.display_name,
      profile_url: IdentityApprovalLink.profile_url(profile)
    ).approved
    mail.message_id = "<professional-identity-approved-#{request.id}@berufe.com.br>"
    begin
      mail.deliver_now
    rescue Berufe::MailDelivery::Error => error
      Rails.error.report(error, context: {verification_request_id: request.id})
      raise
    end
  end
end
