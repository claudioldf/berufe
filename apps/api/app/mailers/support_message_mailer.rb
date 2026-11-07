# frozen_string_literal: true

class SupportMessageMailer < ApplicationMailer
  TOPIC_LABELS = {
    "entrar" => "Entrar",
    "criar-conta" => "Criar conta",
    "excluir-conta" => "Excluir conta",
    "editar-perfil" => "Editar perfil",
    "geral" => "Geral"
  }.freeze

  def received
    @sender_name = params.fetch(:name)
    @sender_email = params.fetch(:email)
    @sender_phone = params[:phone]
    @message_body = params.fetch(:message)
    @topic_label = TOPIC_LABELS.fetch(params.fetch(:topic), "Geral")
    @preheader = "#{@sender_name} escreveu para o suporte da Berufe."

    mail(
      to: params.fetch(:recipient),
      reply_to: email_address_with_name(@sender_email, @sender_name),
      subject: "Contato de suporte — #{@topic_label}"
    )
  end
end
