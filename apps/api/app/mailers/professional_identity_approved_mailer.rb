# frozen_string_literal: true

class ProfessionalIdentityApprovedMailer < ApplicationMailer
  def approved
    @display_name = params.fetch(:display_name)
    @profile_url = params.fetch(:profile_url)
    @artwork_url = "#{@web_origin}/images/email/welcome-features-profile-collage.jpg"
    @preheader = "A equipe da Berufe confirmou sua identidade, #{@display_name}."

    mail(to: params.fetch(:email), subject: "Sua identidade foi verificada na Berufe")
  end
end
