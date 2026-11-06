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
  def self.build(settings: Rails.configuration.x.berufe.environment, name: settings.search_resolver)
    case name
    when "llm"
      Llm.new(
        client: ::Llm::Client.build(settings:),
        adapter: settings.llm_adapter,
        model: settings.openai_model
      )
    when "jev"
      Jev.new(
        api_key: ENV.fetch("TYPESAFE_API_KEY"),
        model: settings.jev_model,
        timeout_seconds: settings.jev_timeout_seconds,
        min_confidence: settings.jev_min_confidence,
        secondary_probability: settings.jev_secondary_probability
      )
    else
      raise ArgumentError, "Unsupported search resolver: #{name.inspect}"
    end
  end
end
