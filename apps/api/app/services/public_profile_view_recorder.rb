# frozen_string_literal: true

class PublicProfileViewRecorder
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
      scope: "profile-view",
      interaction_id: interaction.interaction_id,
      professional_id: profile.id
    )
    return false unless claimed

    ApplicationRecord.transaction do
      metrics.increment_profile_views!(professional_id: profile.id)
      mark_search_opened(interaction)
    end
    true
  rescue => error
    release_claim(profile:, interaction:) if claimed
    Rails.error.report(error)
    logger.error("public_profile_view_recording_failed class=#{error.class}")
    false
  end

  private

  attr_reader :deduplicator, :metrics, :search_events, :logger

  def mark_search_opened(interaction)
    return unless interaction.search_event_id

    search_events
      .where(id: interaction.search_event_id, service_id: interaction.service_id, profile_opened: false)
      .update_all(profile_opened: true, updated_at: Time.current)
  end

  def release_claim(profile:, interaction:)
    deduplicator.release(
      scope: "profile-view",
      interaction_id: interaction.interaction_id,
      professional_id: profile.id
    )
  rescue => error
    Rails.error.report(error)
    logger.error("public_profile_view_dedup_release_failed class=#{error.class}")
  end
end
