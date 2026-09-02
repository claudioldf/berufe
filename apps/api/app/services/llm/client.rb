# frozen_string_literal: true

module Llm
  class Client
    class Unavailable < StandardError; end

    class RateLimited < Unavailable
      attr_reader :retry_after

      def initialize(retry_after:)
        @retry_after = retry_after
        super("LLM provider rate limit reached")
      end
    end

    class InvalidResponse < Unavailable
      attr_reader :raw_response, :provider_request_id

      def initialize(raw_response:, provider_request_id: nil)
        @raw_response = raw_response
        @provider_request_id = provider_request_id
        super("LLM provider returned an invalid structured response")
      end
    end

    Response = Data.define(
      :payload,
      :raw_response,
      :provider_request_id,
      :input_tokens,
      :cached_input_tokens,
      :output_tokens,
      :latency_ms
    )

    def self.build(settings: Rails.configuration.x.berufe.environment)
      strategy = case settings.llm_adapter
      when "fake"
        FakeStrategy.new
      when "openai"
        OpenaiStrategy.new(model: settings.openai_model)
      else
        raise ArgumentError, "Unsupported LLM adapter: #{settings.llm_adapter.inspect}"
      end

      new(strategy:)
    end

    def initialize(strategy:)
      @strategy = strategy
    end

    def parse(expression:, prompt:, schema:, services:, neighborhoods:, default_location:)
      strategy.call(expression:, prompt:, schema:, services:, neighborhoods:, default_location:)
    end

    # Generic strict-JSON completion for any use case beyond search parsing.
    # `fake_payload` is only consumed by the fake adapter, which never calls
    # a provider and simply echoes it back as the structured result.
    def generate(prompt:, input:, schema:, schema_name:, fake_payload:)
      strategy.generate(prompt:, input:, schema:, schema_name:, fake_payload:)
    end

    private

    attr_reader :strategy
  end
end
