# frozen_string_literal: true

class PublicWhatsappHandoffRecorder
  def initialize(
    deduplicator: PublicInteractionDeduplicator.new,
    metrics: ProfessionalDailyMetric,
    search_events: SearchEvent,
    logger: Rails.logger
  )
    @deduplicator = deduplicator
    @metrics = metrics
    @search_events = search_events
    @logger = logger
  end

  def call(profile:, interaction:)
    claimed = deduplicator.claim(
      scope: "whatsapp-#{interaction.source}",
      interaction_id: interaction.interaction_id,
      professional_id: profile.id
    )
    return false unless claimed

    ApplicationRecord.transaction do
      metrics.increment_whatsapp_clicks!(
        professional_id: profile.id,
        source: interaction.source
      )
      mark_search_handoff(interaction)
    end
    true
  rescue => error
    release_claim(profile:, interaction:) if claimed
    Rails.error.report(error)
    logger.error(
      "public_whatsapp_handoff_recording_failed class=#{error.class} source=#{interaction.source}"
    )
    false
  end

  private

  attr_reader :deduplicator, :metrics, :search_events, :logger

  def mark_search_handoff(interaction)
    return unless interaction.search_event_id

    search_events
      .where(
        id: interaction.search_event_id,
        service_id: interaction.service_id,
        whatsapp_handoff_occurred: false
      )
      .update_all(whatsapp_handoff_occurred: true, updated_at: Time.current)
  end

  def release_claim(profile:, interaction:)
    deduplicator.release(
      scope: "whatsapp-#{interaction.source}",
      interaction_id: interaction.interaction_id,
      professional_id: profile.id
    )
  rescue => error
    Rails.error.report(error)
    logger.error("public_whatsapp_handoff_dedup_release_failed class=#{error.class}")
  end
end
