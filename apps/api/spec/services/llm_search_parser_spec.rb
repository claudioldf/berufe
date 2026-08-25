# frozen_string_literal: true

require "rails_helper"

RSpec.describe LlmSearchParser do
  let!(:category) do
    ServiceCategory.create!(
      name: "Interpretação",
      slug: "interpretacao",
      icon: "i-lucide-sparkles",
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
    Neighborhood.create!(
      code: "america-parser",
      name: "América Parser",
      state_code: "SC",
      city_code: "Joinville",
      is_active: true,
      sort_order: 0
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

  it "returns controlled IDs and location codes, stores no raw expression, and reuses the 24-hour cache" do
    parser = described_class.new(client:, settings:)
    expression = "Preciso trocar a fiação da casa da Ana no América Parser"

    first = parser.call(expression:)
    second = parser.call(expression:)

    expect(first).to eq(
      described_class::Criteria.new(
        service_ids: [service.id],
        locations: [
          described_class::Location.new(
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

    analysis = LlmSearchAnalysis.sole
    expect(analysis).to have_attributes(
      adapter: "fake",
      model: "gpt-5-mini",
      provider_request_id: "req_parser",
      cache_hit_count: 1
    )
    expect(analysis.expires_at).to be_within(2.seconds).of(24.hours.from_now)
    expect(analysis.attributes.to_json).not_to include(expression, "Ana")
  end

  it "defaults missing locations to all Joinville and rejects unsupported or unknown locations" do
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
      described_class::Location.new(state_code: "SC", city: "Joinville", neighborhood_code: nil)
    ])

    allow(client).to receive(:parse).and_return(
      provider_response.with(
        payload: {
          "service_ids" => [service.id],
          "locations" => [{"state_code" => "PR", "city" => "Curitiba", "neighborhood" => nil}],
          "keywords" => [],
          "normalized_request" => "Eu preciso de eletricista em Curitiba."
        }
      )
    )
    expect { parser.call(expression: "Eletricista em Curitiba") }
      .to raise_error(described_class::LocationUnsupported)

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
end
