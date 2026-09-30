# frozen_string_literal: true

class ProfessionalWelcomeMailer < ApplicationMailer
  def welcome
    @display_name = params.fetch(:display_name)
    @onboarding_url = "#{@web_origin}/app/professional/onboarding"
    @artwork_url = "#{@web_origin}/images/email/welcome-features-profile-collage.jpg"
    @preheader = "Boas-vindas à Berufe, #{@display_name}. Seu perfil profissional já está pronto para ser completado."

    mail(
      to: params.fetch(:email),
      subject: "Boas-vindas à Berufe"
    )
  end
end
