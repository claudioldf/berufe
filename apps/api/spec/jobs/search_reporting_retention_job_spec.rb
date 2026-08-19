# frozen_string_literal: true

require "rails_helper"

RSpec.describe SearchReportingRetentionJob do
  it "rolls up a complete local day, purges raw rows, and is retry-safe" do
    category = ServiceCategory.create!(
      name: "Retenção", slug: "retencao", icon: "i-lucide-wrench",
      is_active: true, sort_order: 0
    )
    service = Service.create!(
      category:, name: "Pintor", slug: "pintor-retencao", icon: "i-lucide-paintbrush",
      description: "Pintura residencial.", aliases: [], is_active: true, sort_order: 0
    )
    now = Time.zone.parse("2026-08-18 15:00:00")
    occurred_at = now - 91.days
    SearchEvent.create!(
      service:, city_code: "Joinville", result_count: 3,
      profile_opened: true, whatsapp_handoff_occurred: false, created_at: occurred_at
    )
    SearchEvent.create!(
      service:, city_code: "Joinville", result_count: 0,
      profile_opened: false, whatsapp_handoff_occurred: false, created_at: occurred_at + 1.hour
    )

    described_class.perform_now(now:)
    described_class.perform_now(now:)

    expect(SearchEvent.count).to eq(0)
    expect(SearchDailyRollup.sole).to have_attributes(
      service:, searches: 2, with_results: 1, with_three_results: 1,
      with_profile_open: 1, zero_results: 1, thin_results: 0
    )
    aggregate = Admin::Reports::SearchAggregate.new(
      start_at: (occurred_at - 1.day),
      end_at: (occurred_at + 1.day)
    )
    expect(aggregate.totals).to have_attributes(searches: 2, with_results: 1, zero_results: 1)
  end
end
