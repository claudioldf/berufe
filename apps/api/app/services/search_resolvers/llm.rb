# frozen_string_literal: true

module SearchResolvers
  # Interprets a search expression through the configured LLM adapter
  # (OpenAI or fake). The prompt and JSON schema live here so the parser only
  # depends on the resolver contract.
  class Llm
    attr_reader :adapter, :model

    def initialize(client:, adapter:, model:)
      @client = client
      @adapter = adapter
      @model = model
    end

    def call(expression:, services:, neighborhoods:, default_location:)
      client.parse(
        expression:,
        prompt: prompt_for(services:, neighborhoods:, default_location:).render,
        schema: response_schema(services),
        services:,
        neighborhoods:,
        default_location:
      )
    end

    def prompt_digest(services:, neighborhoods:, default_location:)
      prompt_for(services:, neighborhoods:, default_location:).digest
    end

    private

    attr_reader :client

    def prompt_for(services:, neighborhoods:, default_location:)
      LlmSearchPrompt.new(services:, neighborhoods:, default_location:)
    end

    def response_schema(services)
      service_id_items = {type: "string"}
      service_id_items[:enum] = services.map { |service| service.id.to_s } if services.any?
      {
        type: "object",
        additionalProperties: false,
        properties: {
          service_ids: {
            type: "array",
            maxItems: 5,
            items: service_id_items
          },
          locations: {
            type: "array",
            maxItems: 8,
            items: {
              type: "object",
              additionalProperties: false,
              properties: {
                state_code: {type: %w[string null]},
                city: {type: %w[string null]},
                neighborhood: {type: %w[string null]}
              },
              required: %w[state_code city neighborhood]
            }
          },
          keywords: {
            type: "array",
            maxItems: 10,
            items: {type: "string", maxLength: 60}
          },
          normalized_request: {
            type: %w[string null],
            maxLength: WhatsappRequestMessageBuilder::MAXIMUM_REQUEST_LENGTH
          }
        },
        required: %w[service_ids locations keywords normalized_request]
      }
    end
  end
end
