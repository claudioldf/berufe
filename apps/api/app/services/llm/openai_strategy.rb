# frozen_string_literal: true

require "json"
require "openai"

module Llm
  class OpenaiStrategy
    DEFAULT_RETRY_AFTER = 60
    MAXIMUM_RETRY_AFTER = 1.hour.to_i

    def initialize(
      model:,
      client: OpenAI::Client.new(
        api_key: ENV.fetch("OPENAI_API_KEY"),
        timeout: ENV.fetch("OPENAI_TIMEOUT_SECONDS", "8").to_f,
        max_retries: 1,
        logger: Rails.logger,
        log_level: :info
      )
    )
      @model = model
      @client = client
    end

    def call(expression:, prompt:, schema:, services:, neighborhoods:, default_location: nil)
      request_structured_output(
        prompt:,
        input: expression,
        schema:,
        schema_name: "berufe_public_search",
        no_content_message: "OpenAI returned no structured search output",
        error_message: "OpenAI search parsing failed"
      )
    end

    def generate(prompt:, input:, schema:, schema_name:, fake_payload: nil)
      request_structured_output(
        prompt:,
        input:,
        schema:,
        schema_name:,
        no_content_message: "OpenAI returned no structured output",
        error_message: "OpenAI structured generation failed"
      )
    end

    private

    attr_reader :client, :model

    def request_structured_output(prompt:, input:, schema:, schema_name:, no_content_message:, error_message:)
      started_at = Process.clock_gettime(Process::CLOCK_MONOTONIC)
      raw_response = nil
      provider_request_id = nil
      response = client.responses.create(
        model:,
        store: false,
        input: [
          {role: :system, content: prompt},
          {role: :user, content: input}
        ],
        text: {
          format: {
            type: :json_schema,
            name: schema_name,
            strict: true,
            schema:
          }
        },
        max_output_tokens: 800
      )
      content = response.output
        .filter_map { |item| item.content if item.respond_to?(:content) }
        .flatten
        .find { |item| item.respond_to?(:text) }
      raise Client::Unavailable, no_content_message unless content

      usage = response.usage
      raw_response = content.text
      provider_request_id = response._request_id
      Client::Response.new(
        payload: JSON.parse(raw_response),
        raw_response:,
        provider_request_id:,
        input_tokens: usage&.input_tokens,
        cached_input_tokens: usage&.input_tokens_details&.cached_tokens,
        output_tokens: usage&.output_tokens,
        latency_ms: elapsed_milliseconds(started_at)
      )
    rescue OpenAI::Errors::RateLimitError => error
      Rails.error.report(error)
      raise Client::RateLimited.new(retry_after: retry_after(error))
    rescue JSON::ParserError => error
      Rails.error.report(error)
      raise Client::InvalidResponse.new(raw_response:, provider_request_id:)
    rescue OpenAI::Errors::APIError, NoMethodError => error
      Rails.error.report(error)
      raise Client::Unavailable, error_message
    end

    def retry_after(error)
      value = error.headers&.find do |name, _header_value|
        name.to_s.casecmp?("retry-after")
      end&.last
      seconds = Integer(value, exception: false)

      (seconds || DEFAULT_RETRY_AFTER).clamp(1, MAXIMUM_RETRY_AFTER)
    end

    def elapsed_milliseconds(started_at)
      ((Process.clock_gettime(Process::CLOCK_MONOTONIC) - started_at) * 1000).round
    end
  end
end
