# frozen_string_literal: true

# Every quote or service that needs one specific action from the professional,
# each carrying the single server-decided next action as `kind`. Nuxt maps
# `kind` to a label and a dispatch (an inline API call, or a link) — it does
# not re-derive which items belong here. See docs/Berufe_Increment_9_Implementation_Plan.md S065.
class ProfessionalActionInboxQuery
  AWAITING_RESPONSE_THRESHOLD = 3.days

  Item = Data.define(:id, :kind, :title, :subtitle, :sort_at, :recommendation_delivery_channel)

  def call(profile:, now: Time.current)
    items = [
      *unshared_quote_items(profile),
      *awaiting_response_quote_items(profile, now),
      *change_requested_quote_items(profile),
      *service_open_items(profile),
      *recommendation_unsent_items(profile)
    ]
    items.sort_by { |item| item.sort_at }.reverse
  end

  private

  def unshared_quote_items(profile)
    profile.quotes.where(status: "saved").map do |quote|
      Item.new(
        id: quote.id,
        kind: "quote_unshared",
        title: quote_title(quote),
        subtitle: "Ainda não foi enviado ao cliente",
        sort_at: quote.updated_at,
        recommendation_delivery_channel: nil
      )
    end
  end

  def awaiting_response_quote_items(profile, now)
    profile.quotes
      .where(status: "shared", shared_at: ..(now - AWAITING_RESPONSE_THRESHOLD))
      .map do |quote|
        Item.new(
          id: quote.id,
          kind: "quote_awaiting_response",
          title: quote_title(quote),
          subtitle: "Sem resposta desde #{quote.shared_at.to_date.strftime("%d/%m")}",
          sort_at: quote.shared_at,
          recommendation_delivery_channel: nil
        )
      end
  end

  def change_requested_quote_items(profile)
    profile.quotes
      .where(status: "change_requested")
      .includes(:quote_change_requests)
      .filter_map do |quote|
        latest_request = quote.quote_change_requests.first
        next unless latest_request

        Item.new(
          id: quote.id,
          kind: "quote_change_requested",
          title: quote_title(quote),
          subtitle: latest_request.message.truncate(140),
          sort_at: latest_request.requested_at,
          recommendation_delivery_channel: nil
        )
      end
  end

  def service_open_items(profile)
    ServiceJob
      .joins(:quote)
      .where(quotes: {professional_id: profile.id}, status: "approved")
      .includes(:quote)
      .map do |job|
        Item.new(
          id: job.id,
          kind: "service_open",
          title: service_title(job),
          subtitle: "Aprovado, aguardando você concluir",
          sort_at: job.updated_at,
          recommendation_delivery_channel: job.quote.customer_email.present? ? "email" : "whatsapp"
        )
      end
  end

  def recommendation_unsent_items(profile)
    ServiceJob
      .joins(:quote, :customer_recommendation_request)
      .where(quotes: {professional_id: profile.id}, status: "completed")
      .where(customer_recommendation_requests: {delivery_channel: "whatsapp", sent_at: nil})
      .includes(:quote)
      .map do |job|
        Item.new(
          id: job.id,
          kind: "recommendation_unsent",
          title: service_title(job),
          subtitle: "Peça a recomendação pelo WhatsApp",
          sort_at: job.completed_at,
          recommendation_delivery_channel: "whatsapp"
        )
      end
  end

  def quote_title(quote)
    "Orçamento ##{quote.quote_number} · #{quote.customer_name}"
  end

  def service_title(job)
    "#{job.quote.service_description} · #{job.quote.customer_name}"
  end
end
