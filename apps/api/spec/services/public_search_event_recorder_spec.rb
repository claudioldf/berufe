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

  it "creates an anonymous event and short-lived interaction context" do
    interaction = described_class.new.call(
      raw_term: "PINTOR REGISTRADO!",
      normalized_term: "pintor registrado",
      service:,
      neighborhood:,
      result_count: 3
    )

    event = SearchEvent.find(interaction.search_event_id)
    expect(event).to have_attributes(
      service_id: service.id,
      query_text_normalized: "pintor registrado",
      city_code: "Joinville",
      neighborhood_code: neighborhood.code,
      result_count: 3
    )
    expect(PublicInteractionToken.new.verify(interaction.token)).to have_attributes(
      search_event_id: event.id,
      service_id: service.id
    )
  end

  it "redacts sensitive text while preserving the anonymous denominator" do
    interaction = described_class.new.call(
      raw_term: "ana@example.com",
      normalized_term: "ana example com",
      service: nil,
      neighborhood: nil,
      result_count: 0
    )

    expect(SearchEvent.find(interaction.search_event_id)).to have_attributes(
      service_id: nil,
      query_text_normalized: nil,
      result_count: 0
    )
  end

  it "logs only safe diagnostics and suppresses persistence failures" do
    Current.request_id = "search-event-failure"
    allow(SearchEvent).to receive(:create!).and_raise(ActiveRecord::StatementInvalid, "private database detail")
    allow(Rails.logger).to receive(:error)

    interaction = described_class.new.call(
      raw_term: "private@example.com",
      normalized_term: "private example com",
      service: nil,
      neighborhood: nil,
      result_count: 0
    )

    expect(interaction).to be_nil
    expect(Rails.logger).to have_received(:error).with(
      "public_search_event_recording_failed class=ActiveRecord::StatementInvalid request_id=search-event-failure"
    )
  ensure
    Current.reset
  end
end
