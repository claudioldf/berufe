# frozen_string_literal: true

require "rails_helper"

RSpec.describe SearchEvent, type: :model do
  let!(:category) do
    ServiceCategory.create!(
      name: "Demanda agregada",
      slug: "demanda-agregada",
      icon: "i-lucide-chart-no-axes-column",
      is_active: true,
      sort_order: 0
    )
  end
  let!(:service) do
    Service.create!(
      category:,
      name: "Encanador agregado",
      slug: "encanador-agregado",
      icon: "i-lucide-wrench",
      description: "Reparos hidráulicos residenciais.",
      aliases: [],
      is_active: true,
      sort_order: 0
    )
  end
  let!(:neighborhood) do
    create_location_neighborhood(code: "4209102010", name: "América Agregado")
  end

  it "stores only anonymous search context with one-way outcome defaults" do
    event = described_class.create!(
      service:,
      query_text_normalized: "encanador agregado",
      city_code: "4209102",
      neighborhood:,
      result_count: 2
    )

    expect(event).to have_attributes(
      profile_opened: false,
      whatsapp_handoff_occurred: false
    )
    expect(described_class.column_names).not_to include(
      "customer_id",
      "user_account_id",
      "phone_number",
      "visitor_id",
      "cookie_id",
      "ip_address"
    )
  end

  it "stores bounded plain-text LLM audit content without changing the result-count invariant" do
    event = described_class.create!(
      input_prompt: "Preciso de encanador no América",
      raw_llm_response: '{"service_ids":[]}',
      parsed_response: {
        service_ids: [], services: [], locations: [], keywords: [], normalized_request: nil
      },
      audit_status: "completed",
      response_source: "provider",
      llm_prompt_digest: "a" * 64,
      city_code: "4209102",
      result_count: 0
    )

    expect(event.reload.input_prompt).to eq("Preciso de encanador no América")
    expect(event.raw_llm_response).to eq('{"service_ids":[]}')
    expect(event.result_count).to eq(0)

    event.input_prompt = "x" * 201
    expect(event).not_to be_valid
    expect(event.errors).to include(:input_prompt)
  end

  it "permits unmatched redacted demand and rejects invalid aggregate values" do
    event = described_class.new(
      service: nil,
      query_text_normalized: nil,
      city_code: "4202404",
      neighborhood: nil,
      result_count: -1
    )

    expect(event).not_to be_valid
    expect(event.errors).to include(:city, :result_count)

    event.city_code = joinville_city.code
    event.result_count = 0
    expect(event).to be_valid
  end

  it "requires retained query text to already use the public normalization" do
    event = described_class.new(
      query_text_normalized: "Elétrica!",
      city_code: "4209102",
      result_count: 0
    )

    expect(event).not_to be_valid
    expect(event.errors).to include(:query_text_normalized)
  end

  it "indexes report periods by service and neighborhood without a visitor key" do
    index = described_class.connection.indexes(described_class.table_name).find do |candidate|
      candidate.name == "index_search_events_on_time_service_and_neighborhood"
    end

    expect(index&.columns).to eq(%w[created_at service_id neighborhood_code])
  end
end
