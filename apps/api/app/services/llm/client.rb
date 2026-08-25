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

    Response = Data.define(
      :payload,
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

    def parse(expression:, prompt:, schema:, services:, neighborhoods:)
      strategy.call(expression:, prompt:, schema:, services:, neighborhoods:)
    end

    private

    attr_reader :strategy
  end
end
