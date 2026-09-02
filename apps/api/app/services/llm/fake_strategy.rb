# frozen_string_literal: true

module Llm
  class FakeStrategy
    def call(expression:, prompt:, schema:, services:, neighborhoods:, default_location:)
      normalized = PublicSearchText.normalize(expression)
      effective_location = explicit_location(normalized) || default_location
      effective_neighborhoods = if effective_location.city_code == default_location.city_code
        neighborhoods
      else
        Neighborhood.where(city_code: effective_location.city_code).ordered.to_a
      end
      service_ids = services.filter_map do |service|
        terms = [service.name, service.slug, *service.aliases].map { |value| PublicSearchText.normalize(value) }
        service.id if terms.any? { |term| term.present? && normalized.include?(term) }
      end
      matched_neighborhoods = effective_neighborhoods.select do |neighborhood|
        [neighborhood.name, neighborhood.code]
          .map { |value| PublicSearchText.normalize(value) }
          .any? { |term| term.present? && normalized.include?(term) }
      end
      locations = matched_neighborhoods.presence&.map do |neighborhood|
        {
          "state_code" => effective_location.state_code,
          "city" => effective_location.city,
          "neighborhood" => neighborhood.name
        }
      end || [{
        "state_code" => effective_location.state_code,
        "city" => effective_location.city,
        "neighborhood" => nil
      }]
      normalized_request = normalized_request_for(
        services: services.select { |service| service.id.in?(service_ids) },
        neighborhoods: matched_neighborhoods,
        effective_location:
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

    # No network call and no domain logic here: the caller supplies exactly
    # what a real provider would have returned, so behavior stays
    # deterministic in local/test environments regardless of use case.
    def generate(prompt:, input:, schema:, schema_name:, fake_payload:)
      Client::Response.new(
        payload: fake_payload,
        raw_response: JSON.generate(fake_payload),
        provider_request_id: nil,
        input_tokens: nil,
        cached_input_tokens: nil,
        output_tokens: nil,
        latency_ms: 0
      )
    end

    private

    def explicit_location(normalized_expression)
      SupportedSearchLocations.new.all.filter_map do |location|
        normalized_city = PublicSearchText.normalize(location.city)
        pattern = /(?:\A|\b(?:em|na|no|para)\s+)#{Regexp.escape(normalized_city)}(?=\z|[\s,\/])/i
        position = normalized_expression.match(pattern)&.begin(0)
        [location, position, normalized_city.length] if position
      end.min_by { |_location, position, length| [position, -length] }&.first
    end

    def normalized_request_for(services:, neighborhoods:, effective_location:)
      service = services.first
      return unless service

      location = neighborhoods.first&.name || effective_location.city
      "Eu preciso de #{service.name.downcase} em #{location}, #{effective_location.state_code}."
        .first(WhatsappRequestMessageBuilder::MAXIMUM_REQUEST_LENGTH)
    end
  end
end
