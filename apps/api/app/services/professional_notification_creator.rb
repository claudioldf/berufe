# frozen_string_literal: true

class ProfessionalNotificationCreator
  COPY = {
    "profile_moderation_hidden" => ["Perfil ocultado", "Seu perfil foi ocultado pela equipe. Consulte o motivo no painel."],
    "profile_moderation_restored" => ["Perfil restaurado", "Seu perfil voltou a ficar disponível."],
    "verification_request_moderation_approved" => ["Identidade verificada", "A equipe concluiu e aprovou sua verificação de identidade."],
    "verification_request_moderation_rejected" => ["Verificação precisa de ajustes", "A análise da verificação foi concluída. Veja os detalhes para corrigir."],
    "relationship_request_received" => ["Nova solicitação de conexão", "Um profissional quer adicionar uma conexão com você."],
    "relationship_request_accepted" => ["Solicitação de conexão aceita", "Sua solicitação de conexão foi aceita."],
    "relationship_request_declined" => ["Solicitação de conexão recusada", "Sua solicitação de conexão foi recusada."],
    "quote_change_requested" => ["Alteração solicitada no orçamento", "Um cliente pediu uma alteração em um orçamento."],
    "quote_approved" => ["Orçamento aprovado", "Um cliente aprovou um orçamento."],
    "quote_declined" => ["Orçamento recusado", "Um cliente recusou um orçamento."],
    "service_completion_issue_reported" => ["Problema informado no serviço", "O cliente informou uma pendência na conclusão de um serviço."],
    "customer_recommendation_published" => ["Nova recomendação publicada", "Uma recomendação de cliente foi publicada no seu perfil."]
  }.freeze

  def call(recipient:, notification_type:, idempotency_key:, route_params: {}, occurred_at: Time.current)
    return unless eligible?(recipient)

    title, description = COPY.fetch(notification_type)
    Notification.create_or_find_by!(idempotency_key:) do |notification|
      notification.assign_attributes(
        recipient_user_account: recipient,
        notification_type:,
        status: "unread",
        title:,
        description:,
        route_params: route_params.to_h.stringify_keys,
        occurred_at:
      )
    end
  end

  private

  def eligible?(recipient)
    recipient.active? && recipient.professional? && recipient.registered?
  end
end
