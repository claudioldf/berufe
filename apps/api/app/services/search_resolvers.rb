# frozen_string_literal: true

# Resolvers turn a free-text search expression into the structured payload
# `{service_ids, locations, keywords, normalized_request}` consumed by
# LlmSearchParser. Every resolver exposes:
#
#   call(expression:, services:, neighborhoods:, default_location:) # => Llm::Client::Response
#   prompt_digest(services:, neighborhoods:, default_location:)     # => String (cache/audit key part)
#   adapter / model                                                 # => String (cache/audit labels)
#
# Resolvers raise Llm::Client::{Unavailable,RateLimited,InvalidResponse}.
module SearchResolvers
  def self.build(settings: Rails.configuration.x.berufe.environment)
    Llm.new(
      client: ::Llm::Client.build(settings:),
      adapter: settings.llm_adapter,
      model: settings.openai_model
    )
  end
end
