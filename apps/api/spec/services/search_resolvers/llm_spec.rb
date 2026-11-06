# frozen_string_literal: true

require "rails_helper"

RSpec.describe SearchResolvers::Llm do
  let(:category) do
    ServiceCategory.create!(name: "Resolver", slug: "resolver", icon: "i-lucide-zap", is_active: true, sort_order: 0)
  end
  let!(:service) do
    Service.create!(
      category:, name: "Eletricista resolver", slug: "eletricista-resolver", icon: "i-lucide-zap",
      description: "Instalações elétricas.", aliases: [], is_active: true, sort_order: 0
    )
  end
  let(:default_location) do
    SupportedSearchLocations::FALLBACK
  end
  let(:client) { instance_double(Llm::Client) }
  let(:response) do
    Llm::Client::Response.new(
      payload: {}, raw_response: "{}", provider_request_id: nil,
      input_tokens: nil, cached_input_tokens: nil, output_tokens: nil, latency_ms: 0
    )
  end
  let(:resolver) { described_class.new(client:, adapter: "openai", model: "gpt-5-mini") }

  it "exposes the adapter and model used for cache keys and audits" do
    expect(resolver).to have_attributes(adapter: "openai", model: "gpt-5-mini")
  end

  it "sends the rendered prompt and a schema restricted to the active service ids" do
    allow(client).to receive(:parse).and_return(response)

    result = resolver.call(
      expression: "Preciso de eletricista", services: [service], neighborhoods: [], default_location:
    )

    expect(result).to eq(response)
    expect(client).to have_received(:parse).with(
      hash_including(
        expression: "Preciso de eletricista",
        prompt: include(service.name),
        schema: hash_including(
          properties: hash_including(
            service_ids: hash_including(items: {type: "string", enum: [service.id.to_s]})
          )
        )
      )
    )
  end

  it "digests the prompt so catalog changes invalidate cached analyses" do
    first = resolver.prompt_digest(services: [service], neighborhoods: [], default_location:)
    service.update!(description: "Outra descrição.")

    expect(resolver.prompt_digest(services: [service], neighborhoods: [], default_location:)).not_to eq(first)
  end
end
