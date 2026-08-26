# frozen_string_literal: true

require "rails_helper"

RSpec.describe PublicSearchEventRecorder do
  let!(:category) do
    ServiceCategory.create!(
      name: "Registro de busca",
      slug: "registro-de-busca",
      icon: "i-lucide-chart-no-axes-column",
      is_active: true,
      sort_order: 0
    )
  end
  let!(:service) do
    Service.create!(
      category:,
      name: "Pintor registrado",
      slug: "pintor-registrado",
      icon: "i-lucide-paint-roller",
      description: "Pintura residencial.",
      aliases: [],
      is_active: true,
      sort_order: 0
    )
  end
  let!(:neighborhood) do
    Neighborhood.create!(
      code: "centro-registrado",
      name: "Centro Registrado",
      state_code: "SC",
      city_code: "Joinville",
      is_active: true,
      sort_order: 0
    )
  end
  let(:criteria) do
    LlmSearchParser::Criteria.new(
      service_ids: [service.id],
      locations: [
        LlmSearchParser::Location.new(
          state_code: "SC",
          city: "Joinville",
          neighborhood_code: neighborhood.code
        )
      ],
      keywords: [],
      normalized_request: "Eu preciso de pintor no Centro."
    )
  end
  let(:subject) { ["ip", "203.0.113.10"].join("\0") }
  let(:query) { "expression\0preciso de pintor no centro" }

  it "creates an anonymous event and short-lived interaction context" do
    interaction = described_class.new.call(
      criteria:,
      result_count: 3,
      subject:,
      query:
    )

    event = SearchEvent.find(interaction.search_event_id)
    expect(event).to have_attributes(
      service_id: service.id,
      query_text_normalized: nil,
      city_code: "Joinville",
      neighborhood_code: neighborhood.code,
      result_count: 3
    )
    expect(PublicInteractionToken.new.verify(interaction.token)).to have_attributes(
      search_event_id: event.id,
      service_ids: [service.id]
    )
  end

  it "redacts sensitive text while preserving the anonymous denominator" do
    interaction = described_class.new.call(
      criteria: LlmSearchParser::Criteria.new(
        service_ids: [],
        locations: [LlmSearchParser::Location.new(state_code: "SC", city: "Joinville", neighborhood_code: nil)],
        keywords: [],
        normalized_request: nil
      ),
      result_count: 0,
      subject:,
      query:
    )

    expect(SearchEvent.find(interaction.search_event_id)).to have_attributes(
      service_id: nil,
      query_text_normalized: nil,
      result_count: 0
    )
  end

  it "completes the provisional expression event instead of creating a second row" do
    event = PublicSearchAuditRecorder.new.start(expression: "Preciso de pintor no Centro")

    interaction = described_class.new.call(
      criteria:,
      result_count: 8,
      subject:,
      query:,
      event:
    )

    expect(SearchEvent.count).to eq(1)
    expect(event.reload).to have_attributes(
      audit_status: "completed",
      result_count: 8,
      reportable: true,
      service_id: service.id,
      neighborhood_code: neighborhood.code
    )
    expect(interaction.search_event_id).to eq(event.id)
  end

  it "logs only safe diagnostics and suppresses persistence failures" do
    Current.request_id = "search-event-failure"
    error = ActiveRecord::StatementInvalid.new("private database detail")
    allow(SearchEvent).to receive(:create!).and_raise(error)
    allow(Rails.error).to receive(:report)
    allow(Rails.logger).to receive(:error)

    interaction = described_class.new.call(
      criteria:,
      result_count: 0,
      subject:,
      query:
    )

    expect(interaction).to be_nil
    expect(Rails.error).to have_received(:report).with(error)
    expect(Rails.logger).to have_received(:error).with(
      "public_search_event_recording_failed class=ActiveRecord::StatementInvalid request_id=search-event-failure"
    )
  ensure
    Current.reset
  end
end
