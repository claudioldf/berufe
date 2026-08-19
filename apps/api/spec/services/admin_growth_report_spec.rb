# frozen_string_literal: true

require "rails_helper"

RSpec.describe Admin::Reports::GrowthReport do
  let(:category) do
    ServiceCategory.create!(
      name: "Relatórios", slug: "relatorios", icon: "i-lucide-wrench",
      is_active: true, sort_order: 0
    )
  end
  let(:service) do
    Service.create!(
      category:, name: "Eletricista", slug: "eletricista-relatorios",
      icon: "i-lucide-zap", description: "Instalações elétricas.", aliases: [],
      is_active: true, sort_order: 0
    )
  end

  it "calculates the five-stage anonymous journey and suppresses one-off unmatched terms" do
    now = Time.zone.parse("2026-08-18 15:00:00")
    SearchEvent.create!(
      service:, city_code: "Joinville", result_count: 4,
      profile_opened: true, whatsapp_handoff_occurred: true, created_at: now - 1.day
    )
    SearchEvent.create!(
      service:, city_code: "Joinville", result_count: 1,
      profile_opened: false, whatsapp_handoff_occurred: false, created_at: now - 2.days
    )
    SearchEvent.create!(
      query_text_normalized: "servico sensivel", city_code: "Joinville", result_count: 0,
      profile_opened: false, whatsapp_handoff_occurred: false, created_at: now - 1.day
    )

    report = described_class.new(period: "last_7_days", generated_at: now).call

    expect(report.dig(:discovery, :stages).map { |stage| [stage[:key], stage[:numerator]] }).to eq(
      [["searches", 3], ["results", 2], ["choice", 1], ["profile_open", 1], ["contact", 1]]
    )
    expect(report.dig(:discovery, :demand)).to eq([{label: "Eletricista", value: 2}])
    expect(report.dig(:discovery, :gaps)).to be_empty
    expect(report.dig(:summary, :search_coverage, :rate)).to be_within(0.001).of(2.fdiv(3))
    expect(report.dig(:summary, :search_coverage, :comparison, :directional)).to be(true)
    expect(report.dig(:moderation, :oldest_pending_target_hours)).to eq(24)
  end
end
