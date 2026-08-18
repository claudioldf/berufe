# frozen_string_literal: true

class PublicWhatsappInteractionResolver
  class InvalidInteraction < StandardError; end

  SOURCES = %w[public_profile search_result].freeze
  Context = Data.define(
    :source,
    :interaction_id,
    :service_id,
    :service_name,
    :search_event_id
  )

  def initialize(
    search_tokens: PublicInteractionToken.new,
    profile_tokens: PublicProfileInteractionToken.new
  )
    @search_tokens = search_tokens
    @profile_tokens = profile_tokens
  end

  def call(profile:, source:, token:)
    raise InvalidInteraction unless source.in?(SOURCES)

    token_context = verify_token(profile:, source:, token:)
    service = profile.published_revision.professional_profile_services
      .includes(:service)
      .find_by(service_id: token_context.service_id)
      &.service
    raise InvalidInteraction unless service

    Context.new(
      source:,
      interaction_id: interaction_id(source:, token_context:),
      service_id: service.id,
      service_name: service.name,
      search_event_id: token_context.search_event_id
    )
  end

  private

  attr_reader :search_tokens, :profile_tokens

  def verify_token(profile:, source:, token:)
    context = if source == "search_result"
      search_tokens.verify(token)
    else
      profile_tokens.verify(token)
    end
    raise InvalidInteraction unless context
    raise InvalidInteraction if source == "public_profile" && context.professional_id != profile.id

    context
  end

  def interaction_id(source:, token_context:)
    return token_context.search_event_id if source == "search_result"

    token_context.interaction_id
  end
end
