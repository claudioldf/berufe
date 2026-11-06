# frozen_string_literal: true

class AdminNotificationMailerPreview < ActionMailer::Preview
  def professional_registered
    AdminNotificationMailer.with(
      email: "admin@berufe.com.br",
      display_name: "Claudio Dias",
      registered_at: Time.current,
      claimed: false
    ).professional_registered
  end

  def verification_submitted
    AdminNotificationMailer.with(
      email: "admin@berufe.com.br",
      display_name: "Claudio Dias",
      submitted_at: Time.current
    ).verification_submitted
  end
end
