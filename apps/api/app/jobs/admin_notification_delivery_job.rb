# frozen_string_literal: true

class AdminNotificationDeliveryJob < ApplicationJob
  EVENTS = %w[professional_registered verification_submitted].freeze

  queue_as :default

  retry_on Berufe::MailDelivery::ProviderUnavailable,
    wait: :polynomially_longer,
    attempts: 5
  discard_on Berufe::MailDelivery::Rejected

  def perform(event, subject_id, email, mailer: AdminNotificationMailer)
    params = mail_params(event, subject_id)
    return unless params

    mail = mailer.with(email:, **params).public_send(event)
    recipient_key = Digest::SHA256.hexdigest(email)[0, 12]
    mail.message_id = "<admin-#{event.tr("_", "-")}-#{subject_id}-#{recipient_key}@berufe.com.br>"
    begin
      mail.deliver_now
    rescue Berufe::MailDelivery::Error => error
      Rails.error.report(error, context: {event:, subject_id:})
      raise
    end
  end

  private

  def mail_params(event, subject_id)
    case event
    when "professional_registered" then registration_params(subject_id)
    when "verification_submitted" then verification_params(subject_id)
    else raise ArgumentError, "unknown admin notification event: #{event}"
    end
  end

  def registration_params(account_id)
    account = UserAccount.includes(:professional_profile).find_by(id: account_id)
    return unless account&.registration_completed? && account.professional_profile

    profile = account.professional_profile
    {
      display_name: profile.display_name,
      registered_at: account.registered_at,
      claimed: profile.creation_source == "external"
    }
  end

  def verification_params(request_id)
    request = VerificationRequest.includes(:professional_profile).find_by(id: request_id)
    return unless request

    {display_name: request.professional_profile.display_name, submitted_at: request.submitted_at}
  end
end
