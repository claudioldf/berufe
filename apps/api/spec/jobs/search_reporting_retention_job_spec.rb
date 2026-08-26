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

  it "retains six-month LLM audits after rollup and never reports failed audits" do
    now = Time.zone.parse("2026-08-25 15:00:00")
    completed_audit = SearchEvent.create!(
      input_prompt: "Preciso de pintor",
      raw_llm_response: '{"service_ids":[]}',
      parsed_response: {
        service_ids: [], services: [], locations: [], keywords: [], normalized_request: nil
      },
      audit_status: "completed",
      response_source: "provider",
      llm_adapter: "fake",
      llm_model: "gpt-5-mini",
      llm_prompt_digest: "a" * 64,
      city_code: "Joinville",
      result_count: 2,
      reportable: true,
      created_at: now - 91.days
    )
    failed_audit = SearchEvent.create!(
      input_prompt: "Preciso de eletricista",
      audit_status: "application_rate_limited",
      city_code: "Joinville",
      result_count: 0,
      reportable: false,
      created_at: now - 91.days
    )
    expired_audit = SearchEvent.create!(
      input_prompt: "Preciso de encanador",
      audit_status: "provider_unavailable",
      city_code: "Joinville",
      result_count: 0,
      reportable: false,
      created_at: now - 6.months - 1.minute
    )
    discarded_failed_row = SearchEvent.create!(
      audit_status: "search_failed",
      city_code: "Joinville",
      result_count: 0,
      reportable: false,
      created_at: now - 91.days
    )

    described_class.perform_now(now:)
    described_class.perform_now(now:)

    expect(completed_audit.reload).to have_attributes(
      input_prompt: "Preciso de pintor",
      raw_llm_response: '{"service_ids":[]}',
      parsed_response: include("service_ids" => []),
      response_source: "provider",
      llm_adapter: "fake",
      llm_model: "gpt-5-mini",
      llm_prompt_digest: "a" * 64,
      audit_status: "completed",
      result_count: 2,
      reportable: false
    )
    expect(failed_audit.reload.input_prompt).to eq("Preciso de eletricista")
    expect(SearchEvent.exists?(expired_audit.id)).to be(false)
    expect(SearchEvent.exists?(discarded_failed_row.id)).to be(false)
    expect(SearchDailyRollup.sum(:searches)).to eq(1)
  end

  it "removes expired search-event deduplication claims" do
    now = Time.zone.parse("2026-08-26 15:00:00")
    expired_event = SearchEvent.create!(city_code: "Joinville", result_count: 1, created_at: now)
    retained_event = SearchEvent.create!(city_code: "Joinville", result_count: 1, created_at: now)
    expired = PublicSearchEventDeduplication.create!(
      search_event: expired_event,
      subject_digest: "a" * 64,
      query_digest: "b" * 64,
      result_count: 1,
      expires_at: now
    )
    retained = PublicSearchEventDeduplication.create!(
      search_event: retained_event,
      subject_digest: "c" * 64,
      query_digest: "d" * 64,
      result_count: 1,
      expires_at: now + 1.second
    )

    described_class.perform_now(now:)

    expect(PublicSearchEventDeduplication.exists?(expired.id)).to be(false)
    expect(PublicSearchEventDeduplication.exists?(retained.id)).to be(true)
  end
end
