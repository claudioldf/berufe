# frozen_string_literal: true

require "rails_helper"

RSpec.describe LlmSearchParser do
  let!(:category) do
    ServiceCategory.create!(
      name: "Interpretação",
      slug: "interpretacao",
      icon: "i-lucide-scan-search",
      is_active: true,
      sort_order: 0
    )
  end
  let!(:service) do
    Service.create!(
      category:,
      name: "Eletricista parser",
      slug: "eletricista-parser",
      icon: "i-lucide-zap",
      description: "Instalações elétricas.",
      aliases: ["elétrica parser"],
      is_active: true,
      sort_order: 0
    )
  end
  let!(:america) do
    create_location_neighborhood(code: "4209102012", name: "América Parser")
  end
  let!(:batel) do
    create_location_neighborhood(
      code: "4106902012",
      name: "Batel Parser",
      city: curitiba_city
    )
  end
  let(:settings) do
    Data.define(:llm_adapter, :openai_model).new(
      llm_adapter: "fake",
      openai_model: "gpt-5-mini"
    )
  end
  let(:client) { instance_double(Llm::Client) }
  let(:provider_response) do
    Llm::Client::Response.new(
      payload: {
        "service_ids" => [service.id, service.id, SecureRandom.uuid],
        "locations" => [
          {"state_code" => "sc", "city" => "Joinville", "neighborhood" => "América Parser"}
        ],
        "keywords" => ["troca de fiação", "ana@example.com"],
        "normalized_request" => "Eu preciso trocar a fiação no América Parser."
      },
      raw_response: '{"service_ids":["controlled"]}',
      provider_request_id: "req_parser",
      input_tokens: 120,
      cached_input_tokens: 20,
      output_tokens: 30,
      latency_ms: 45
    )
  end

  before do
    allow(client).to receive(:parse).and_return(provider_response)
  end

  it "returns controlled criteria and records provider and cache audit details" do
    parser = described_class.new(client:, settings:)
    expression = "Preciso trocar a fiação da casa da Ana no América Parser"
    recorder = PublicSearchAuditRecorder.new
    first_event = recorder.start(expression:, city_code: joinville_city.code)

    first = parser.call(expression:, audit_event: first_event)
    second_event = recorder.start(expression:, city_code: joinville_city.code)
    second = parser.call(expression:, audit_event: second_event)

    expect(first).to eq(
      described_class::Criteria.new(
        service_ids: [service.id],
        locations: [
          described_class::Location.new(
            city_code: joinville_city.code,
            state_code: "SC",
            city: "Joinville",
            neighborhood_code: america.code
          )
        ],
        keywords: ["troca de fiacao"],
        normalized_request: "Eu preciso trocar a fiação no América Parser."
      )
    )
    expect(second).to eq(first)
    expect(client).to have_received(:parse).once
    expect(client).to have_received(:parse).with(
      hash_including(
        prompt: include("Se o usuário não informar cidade, use SC e Joinville"),
        default_location: have_attributes(state_code: "SC", city: "Joinville")
      )
    )

    analysis = LlmSearchAnalysis.sole
    expect(analysis).to have_attributes(
      adapter: "fake",
      model: "gpt-5-mini",
      provider_request_id: "req_parser",
      cache_hit_count: 1
    )
    expect(first_event.reload).to have_attributes(
      raw_llm_response: provider_response.raw_response,
      response_source: "provider",
      llm_adapter: "fake",
      llm_model: "gpt-5-mini"
    )
    expect(first_event.parsed_response).to include(
      "service_ids" => [service.id],
      "services" => [{"id" => service.id, "name" => service.name}],
      "normalized_request" => "Eu preciso trocar a fiação no América Parser."
    )
    expect(second_event.reload).to have_attributes(
      raw_llm_response: provider_response.raw_response,
      response_source: "cache"
    )
    expect(analysis.expires_at).to be_within(2.seconds).of(24.hours.from_now)
    expect(analysis.attributes.to_json).not_to include(expression, "Ana")
  end

  it "uses the selected city only as fallback and resolves an explicit city and its neighborhoods" do
    parser = described_class.new(client:, settings:)
    allow(client).to receive(:parse).and_return(
      provider_response.with(
        payload: {
          "service_ids" => [service.id],
          "locations" => [],
          "keywords" => [],
          "normalized_request" => "Eu preciso de eletricista."
        }
      )
    )
    expect(parser.call(expression: "Preciso de eletricista").locations).to eq([
      described_class::Location.new(
        city_code: joinville_city.code,
        state_code: "SC",
        city: "Joinville",
        neighborhood_code: nil
      )
    ])

    allow(client).to receive(:parse).and_return(
      provider_response.with(
        payload: {
          "service_ids" => [service.id],
          "locations" => [{"state_code" => nil, "city" => "Curitiba", "neighborhood" => "Batel Parser"}],
          "keywords" => [],
          "normalized_request" => "Eu preciso de eletricista no Batel."
        }
      )
    )
    expect(parser.call(expression: "Eletricista no Batel em Curitiba").locations).to eq([
      described_class::Location.new(
        city_code: curitiba_city.code,
        state_code: "PR",
        city: "Curitiba",
        neighborhood_code: batel.code
      )
    ])

    allow(client).to receive(:parse).and_return(
      provider_response.with(
        payload: {
          "service_ids" => [service.id],
          "locations" => [{"state_code" => "SC", "city" => "Joinville", "neighborhood" => "Bairro inventado"}],
          "keywords" => [],
          "normalized_request" => "Eu preciso de eletricista no Bairro inventado."
        }
      )
    )
    expect { parser.call(expression: "Eletricista no Bairro inventado") }
      .to raise_error(described_class::LocationUnrecognized)
  end

  it "uses only the first explicitly parsed city" do
    parser = described_class.new(client:, settings:)
    allow(client).to receive(:parse).and_return(
      provider_response.with(
        payload: {
          "service_ids" => [service.id],
          "locations" => [
            {"state_code" => "PR", "city" => "Curitiba", "neighborhood" => nil},
            {"state_code" => "SC", "city" => "Joinville", "neighborhood" => nil}
          ],
          "keywords" => [],
          "normalized_request" => "Eu preciso de eletricista em Curitiba."
        }
      )
    )

    expect(parser.call(expression: "Eletricista em Curitiba ou Joinville").locations).to eq([
      described_class::Location.new(
        city_code: curitiba_city.code,
        state_code: "PR",
        city: "Curitiba",
        neighborhood_code: nil
      )
    ])
  end

  it "drops unsafe or malformed normalized contact requests before caching them" do
    allow(client).to receive(:parse).and_return(
      provider_response.with(
        payload: provider_response.payload.merge(
          "normalized_request" => "Olá, meu e-mail é ana@example.com"
        )
      )
    )

    result = described_class.new(client:, settings:).call(expression: "Preciso de eletricista")

    expect(result.normalized_request).to be_nil
    expect(LlmSearchAnalysis.sole.parsed_result.fetch("normalized_request")).to be_nil
  end

  it "validates the expression before calling a provider" do
    parser = described_class.new(client:, settings:)

    expect { parser.call(expression: " ") }.to raise_error(described_class::InvalidExpression)
    expect { parser.call(expression: "x" * 201) }.to raise_error(described_class::InvalidExpression)
    expect(client).not_to have_received(:parse)
  end

  it "preserves provider rate limits for the HTTP boundary" do
    allow(client).to receive(:parse)
      .and_raise(Llm::Client::RateLimited.new(retry_after: 37))

    expect {
      described_class.new(client:, settings:).call(expression: "Preciso de eletricista")
    }.to raise_error(described_class::ProviderRateLimited) do |error|
      expect(error.retry_after).to eq(37)
    end
  end

  it "marks invalid provider output as rejected while retaining the exact response" do
    allow(client).to receive(:parse).and_raise(
      Llm::Client::InvalidResponse.new(
        raw_response: "not valid json",
        provider_request_id: "req_invalid"
      )
    )
    event = PublicSearchAuditRecorder.new.start(
      expression: "Preciso de eletricista",
      city_code: joinville_city.code
    )

    expect {
      described_class.new(client:, settings:).call(
        expression: "Preciso de eletricista",
        audit_event: event
      )
    }.to raise_error(described_class::ProviderUnavailable)

    expect(event.reload).to have_attributes(
      audit_status: "response_rejected",
      raw_llm_response: "not valid json",
      response_source: "provider",
      llm_provider_request_id: "req_invalid",
      result_count: 0,
      reportable: false
    )
  end
end
