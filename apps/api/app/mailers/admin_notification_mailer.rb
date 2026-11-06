# frozen_string_literal: true

class AdminNotificationMailer < ApplicationMailer
  TIME_ZONE = ProfessionalDailyMetric::PRODUCT_TIME_ZONE

  def professional_registered
    @display_name = params.fetch(:display_name)
    @claimed = params.fetch(:claimed, false)
    @occurred_at = format_time(params.fetch(:registered_at))
    @event_title = @claimed ? "Perfil reivindicado" : "Perfil criado"
    @cta_label = "Ver profissionais"
    @cta_url = "#{@web_origin}/app/admin/professionals"
    @eyebrow = "Novo cadastro"
    @heading = "Novo cadastro profissional"
    @preheader = "#{@display_name} concluiu o cadastro profissional na Berufe."

    mail(to: params.fetch(:email), subject: "Novo cadastro profissional na Berufe")
  end

  def verification_submitted
    @display_name = params.fetch(:display_name)
    @occurred_at = format_time(params.fetch(:submitted_at))
    @event_title = "Documento de identidade enviado"
    @cta_label = "Abrir fila de moderação"
    @cta_url = "#{@web_origin}/app/admin"
    @eyebrow = "Fila de moderação"
    @heading = "Nova identidade aguardando análise"
    @preheader = "#{@display_name} enviou um documento de identidade para análise."

    mail(to: params.fetch(:email), subject: "Nova identidade aguardando análise")
  end

  private

  def format_time(time)
    time.in_time_zone(TIME_ZONE).strftime("%d/%m/%Y às %H:%M")
  end
end
