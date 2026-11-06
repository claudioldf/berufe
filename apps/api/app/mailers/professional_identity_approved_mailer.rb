# frozen_string_literal: true

class ProfessionalIdentityApprovedMailer < ApplicationMailer
  def approved
    @display_name = params.fetch(:display_name)
    @profile_url = params.fetch(:profile_url)
    @preheader = "A equipe da Berufe confirmou sua identidade, #{@display_name}."

    mail(to: params.fetch(:email), subject: "Sua identidade foi verificada na Berufe")
  end
end
