# frozen_string_literal: true

require "rails_helper"

RSpec.describe PublicServiceDemand do
  let!(:category) do
    ServiceCategory.create!(
      name: "Demanda pública",
      slug: "demanda-publica",
      icon: "i-lucide-wrench",
      is_active: true,
      sort_order: 0
    )
  end
  let!(:electrician) do
    Service.create!(
      category:,
      name: "Eletricista demandado",
      slug: "eletricista-demandado",
      icon: "i-lucide-zap",
      description: "Instalações elétricas residenciais.",
      aliases: [],
      is_active: true,
      sort_order: 0
    )
  end

  it "does not release a raw count below the privacy threshold" do
    2.times { create_search_event }

    result = described_class.new.call(service_id: electrician.id, city_code: joinville_city.code)

    expect(result.searches).to eq(2)
    expect(result.released).to eq(false)
  end

  it "releases the total once it reaches the privacy threshold" do
    3.times { create_search_event }

    result = described_class.new.call(service_id: electrician.id, city_code: joinville_city.code)

    expect(result.searches).to eq(3)
    expect(result.released).to eq(true)
  end

  it "combines not-yet-rolled-up events with rolled-up daily totals without double counting" do
    create_search_event
    SearchDailyRollup.create!(
      service: electrician,
      city: joinville_city,
      report_date: 5.days.ago.to_date,
      searches: 2,
      with_results: 2,
      with_three_results: 0,
      with_profile_open: 0,
      with_whatsapp_handoff: 0,
      zero_results: 0,
      thin_results: 0
    )

    result = described_class.new.call(service_id: electrician.id, city_code: joinville_city.code)

    expect(result.searches).to eq(3)
    expect(result.released).to eq(true)
  end

  it "ignores events already excluded from reporting and events outside the 30-day window" do
    create_search_event(reportable: false)
    create_search_event(created_at: 40.days.ago)
    create_search_event

    result = described_class.new.call(service_id: electrician.id, city_code: joinville_city.code)

    expect(result.searches).to eq(1)
    expect(result.released).to eq(false)
  end

  it "does not mix in another service's or city's searches" do
    other_service = Service.create!(
      category:,
      name: "Pintor demandado",
      slug: "pintor-demandado",
      icon: "i-lucide-paintbrush",
      description: "Pintura residencial.",
      aliases: [],
      is_active: true,
      sort_order: 1
    )
    3.times { create_search_event(service: other_service) }
    3.times { create_search_event(city: curitiba_city) }

    result = described_class.new.call(service_id: electrician.id, city_code: joinville_city.code)

    expect(result.searches).to eq(0)
    expect(result.released).to eq(false)
  end

  private

  def create_search_event(service: electrician, city: joinville_city, created_at: 1.day.ago, reportable: true)
    SearchEvent.create!(
      service:,
      city:,
      result_count: 1,
      profile_opened: false,
      whatsapp_handoff_occurred: false,
      reportable:,
      created_at:,
      updated_at: created_at
    )
  end
end
