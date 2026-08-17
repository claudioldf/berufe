# frozen_string_literal: true

require "digest"

class PublicInteractionDeduplicator
  TTL = 10.minutes

  def initialize(cache: Rails.application.config.x.berufe.public_interaction_cache)
    @cache = cache
  end

  def claim(scope:, interaction_id:, professional_id:)
    cache.write(
      key(scope:, interaction_id:, professional_id:),
      true,
      expires_in: TTL,
      unless_exist: true
    )
  end

  def release(scope:, interaction_id:, professional_id:)
    cache.delete(key(scope:, interaction_id:, professional_id:))
  end

  private

  attr_reader :cache

  def key(scope:, interaction_id:, professional_id:)
    digest = Digest::SHA256.hexdigest([scope, interaction_id, professional_id].join(":"))
    "public-interaction:#{digest}"
  end
end
