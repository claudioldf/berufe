# frozen_string_literal: true

class ProfessionalWelcomeEmailDeliveryJob < ApplicationJob
  queue_as :default
  self.enqueue_after_transaction_commit = true

  retry_on Berufe::MailDelivery::ProviderUnavailable,
    wait: :polynomially_longer,
    attempts: 5
  discard_on Berufe::MailDelivery::Rejected

  def perform(user_account_id, mailer: ProfessionalWelcomeMailer)
    account = UserAccount.includes(:professional_profile).find_by(id: user_account_id)
    return unless account&.registration_completed?
    return if account.email.blank?
    return if account.welcome_email_sent_at.present?

    mail = mailer.with(
      email: account.email,
      display_name: account.professional_profile.display_name
    ).welcome
    mail.message_id = "<professional-welcome-#{account.id}@berufe.com.br>"
    begin
      mail.deliver_now
    rescue Berufe::MailDelivery::Error => error
      Rails.error.report(error, context: {user_account_id: account.id})
      raise
    end

    account.with_lock do
      next if account.welcome_email_sent_at.present?

      account.update!(welcome_email_sent_at: Time.current)
    end
  end
end
