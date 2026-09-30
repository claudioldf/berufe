# frozen_string_literal: true

class EmailOtpMailer < ApplicationMailer
  def verification_code
    @code = params.fetch(:code)
    @expires_in_minutes = (params.fetch(:expires_in).to_i / 60.0).ceil
    @preheader = "Use o código #{@code} para acessar seu perfil profissional na Berufe."

    mail(
      to: params.fetch(:email),
      subject: "Seu código de acesso à Berufe"
    )
  end
end
