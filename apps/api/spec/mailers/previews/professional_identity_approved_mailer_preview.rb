# frozen_string_literal: true

class ProfessionalIdentityApprovedMailerPreview < ActionMailer::Preview
  def approved
    ProfessionalIdentityApprovedMailer.with(
      email: "claudioldf@gmail.com",
      display_name: "Claudio Dias",
      profile_url: "#{ENV.fetch("WEB_ORIGIN")}/profissionais/claudio-dias"
    ).approved
  end
end
