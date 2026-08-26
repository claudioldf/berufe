# frozen_string_literal: true

module Llm
  class FakeStrategy
    def call(expression:, prompt:, schema:, services:, neighborhoods:)
      normalized = PublicSearchText.normalize(expression)
      service_ids = services.filter_map do |service|
        terms = [service.name, service.slug, *service.aliases].map { |value| PublicSearchText.normalize(value) }
        service.id if terms.any? { |term| term.present? && normalized.include?(term) }
      end
      matched_neighborhoods = neighborhoods.select do |neighborhood|
        [neighborhood.name, neighborhood.code]
          .map { |value| PublicSearchText.normalize(value) }
          .any? { |term| term.present? && normalized.include?(term) }
      end
      locations = matched_neighborhoods.presence&.map do |neighborhood|
        {"state_code" => "SC", "city" => "Joinville", "neighborhood" => neighborhood.name}
      end || [{"state_code" => "SC", "city" => "Joinville", "neighborhood" => nil}]
      normalized_request = normalized_request_for(
        services: services.select { |service| service.id.in?(service_ids) },
        neighborhoods: matched_neighborhoods
      )

      payload = {
        "service_ids" => service_ids,
        "locations" => locations,
        "keywords" => [],
        "normalized_request" => normalized_request
      }
      Client::Response.new(
        payload:,
        raw_response: JSON.generate(payload),
        provider_request_id: nil,
        input_tokens: nil,
        cached_input_tokens: nil,
        output_tokens: nil,
        latency_ms: 0
      )
    end

    private

    def normalized_request_for(services:, neighborhoods:)
      service = services.first
      return unless service

      location = neighborhoods.first&.name || LlmSearchParser::DEFAULT_CITY
      "Eu preciso de #{service.name.downcase} em #{location}, #{LlmSearchParser::DEFAULT_STATE_CODE}."
        .first(WhatsappRequestMessageBuilder::MAXIMUM_REQUEST_LENGTH)
    end
  end
end
