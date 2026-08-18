# frozen_string_literal: true

class PublicProfileInteractionIssuer
  def initialize(
    search_tokens: PublicInteractionToken.new,
    profile_tokens: PublicProfileInteractionToken.new
  )
    @search_tokens = search_tokens
    @profile_tokens = profile_tokens
  end

  def call(profile:, search_token: nil)
    revision = profile.published_revision
    service_ids = revision.professional_profile_services.map(&:service_id)
    primary_service_id = revision.professional_profile_services.find(&:is_primary)&.service_id
    search_context = search_tokens.verify(search_token) if search_token.present?
    search_context = nil unless search_context&.service_id&.in?(service_ids)

    profile_tokens.issue(
      professional_id: profile.id,
      service_id: search_context&.service_id || primary_service_id,
      search_event_id: search_context&.search_event_id
    )
  end

  private

  attr_reader :search_tokens, :profile_tokens
end
