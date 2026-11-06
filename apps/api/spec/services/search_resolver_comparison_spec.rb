# frozen_string_literal: true

require "rails_helper"

RSpec.describe SearchResolverComparison do
  let!(:category) do
    ServiceCategory.create!(name: "Comparação", slug: "comparacao", icon: "i-lucide-zap", is_active: true, sort_order: 0)
  end
  let!(:service) do
    Service.create!(
      category:, name: "Eletricista comparação", slug: "eletricista-comparacao", icon: "i-lucide-zap",
      description: "Instalações elétricas.", aliases: [], is_active: true, sort_order: 0
    )
  end
  let!(:america) { create_location_neighborhood(code: "4209102012", name: "América Comparação") }

  def response_with(payload, raw_response: JSON.generate(payload))
    Llm::Client::Response.new(
      payload:, raw_response:, provider_request_id: nil,
      input_tokens: nil, cached_input_tokens: nil, output_tokens: nil, latency_ms: 0
    )
  end

  def stub_resolver(adapter:, model:, response: nil, error: nil)
    instance_double(
      SearchResolvers::Llm,
      adapter:, model:, prompt_digest: "a" * 64
    ).tap do |resolver|
      if error
        allow(resolver).to receive(:call).and_raise(error)
      else
        allow(resolver).to receive(:call).and_return(response)
      end
    end
  end

  let(:payload) do
    {
      "service_ids" => [service.id],
      "locations" => [{"state_code" => "SC", "city" => "Joinville", "neighborhood" => "América Comparação"}],
      "keywords" => [],
      "normalized_request" => "Eu preciso de eletricista comparação em América Comparação, SC."
    }
  end
  let(:jev_raw) do
    JSON.generate([{
      "answers" => {
        "wants_service" => {"type" => "noul", "noul" => 0.97},
        "service" => {"type" => "choice", "choice" => "eletricista-comparacao", "confidence" => 0.934, "probabilities" => {}}
      }
    }])
  end

  it "runs every resolver without caching and summarizes services, locations and JEV signals" do
    resolvers = {
      "llm" => stub_resolver(adapter: "fake", model: "gpt-5-mini", response: response_with(payload)),
      "jev" => stub_resolver(adapter: "jev", model: "jev-latest", response: response_with(payload, raw_response: jev_raw))
    }
    comparison = described_class.new(builder: ->(name:) { resolvers.fetch(name) })

    llm, jev = comparison.call(expression: "Preciso de um eletricista na América")

    expect(llm).to have_attributes(
      name: "llm", adapter: "fake", model: "gpt-5-mini", services: [service.name],
      locations: ["América Comparação, Joinville/SC"], signals: nil, error: nil
    )
    expect(jev).to have_attributes(
      name: "jev", adapter: "jev", services: [service.name],
      signals: "wants_service=0.97 service=eletricista-comparacao(0.93)"
    )
    expect(jev.normalized_request).to start_with("Eu preciso de eletricista")
    expect(LlmSearchAnalysis.count).to eq(0)
    expect(SearchEvent.count).to eq(0)
  end

  it "reports a failing resolver without stopping the others" do
    resolvers = {
      "llm" => stub_resolver(adapter: "fake", model: "gpt-5-mini", response: response_with(payload)),
      "jev" => stub_resolver(adapter: "jev", model: "jev-latest", error: Llm::Client::Unavailable.new("JEV returned HTTP 500"))
    }
    comparison = described_class.new(builder: ->(name:) { resolvers.fetch(name) })

    llm, jev = comparison.call(expression: "Preciso de um eletricista")

    expect(llm.error).to be_nil
    expect(jev).to have_attributes(services: [], error: "ProviderUnavailable: JEV returned HTTP 500")
  end

  it "reports a resolver that cannot be built, such as JEV without its API key" do
    builder = lambda do |name:|
      (name == "jev") ? raise(KeyError, "key not found: \"TYPESAFE_API_KEY\"") : stub_resolver(
        adapter: "fake", model: "gpt-5-mini", response: response_with(payload)
      )
    end

    jev = described_class.new(builder:).call(expression: "Preciso de um eletricista").last

    expect(jev.error).to include("TYPESAFE_API_KEY")
  end
end
