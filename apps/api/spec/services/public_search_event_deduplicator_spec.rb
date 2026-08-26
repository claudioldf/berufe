# frozen_string_literal: true

require "rails_helper"

RSpec.describe PublicSearchEventDeduplicator do
  it "reuses an event for the same subject, query, and result count within one day" do
    now = Time.zone.parse("2026-08-26 10:00:00")
    original = create_event(result_count: 3, created_at: now)
    duplicate = create_event(result_count: 3, created_at: now + 2.hours)

    expect(call(original, now:)).to eq(original)
    expect(call(duplicate, now: now + 2.hours)).to eq(original)
    expect(SearchEvent.pluck(:id)).to eq([original.id])
    expect(described_class::WINDOW).to eq(1.day)
  end

  it "keeps searches with another result count, query, subject, or elapsed window" do
    now = Time.zone.parse("2026-08-26 10:00:00")
    original = create_event(result_count: 3, created_at: now)
    changed_count = create_event(result_count: 4, created_at: now + 1.hour)
    changed_query = create_event(result_count: 3, created_at: now + 2.hours)
    changed_subject = create_event(result_count: 3, created_at: now + 3.hours)
    expired_window = create_event(result_count: 3, created_at: now + 1.day)

    expect(call(original, now:)).to eq(original)
    expect(call(changed_count, result_count: 4, now: now + 1.hour)).to eq(changed_count)
    expect(call(changed_query, query: "expression\0encanador", now: now + 2.hours)).to eq(changed_query)
    expect(
      call(changed_subject, subject: ["ip", "203.0.113.11"].join("\0"), now: now + 3.hours)
    ).to eq(changed_subject)
    expect(call(expired_window, now: now + 1.day)).to eq(expired_window)
    expect(SearchEvent.count).to eq(5)
  end

  it "stores only keyed digests in the bounded claim" do
    event = create_event(result_count: 0, created_at: Time.current)

    call(event, result_count: 0)

    claim = PublicSearchEventDeduplication.sole
    expect(claim.subject_digest).to match(/\A[0-9a-f]{64}\z/)
    expect(claim.query_digest).to match(/\A[0-9a-f]{64}\z/)
    expect(claim.attributes.to_json).not_to include("203.0.113.10", "preciso de pintor")
  end

  private

  def call(
    event,
    subject: ["ip", "203.0.113.10"].join("\0"),
    query: "expression\0preciso de pintor",
    result_count: 3,
    now: Time.current
  )
    described_class.new.reuse_or_claim!(event:, subject:, query:, result_count:, now:)
  end

  def create_event(result_count:, created_at:)
    SearchEvent.create!(
      input_prompt: "Preciso de pintor",
      audit_status: "completed",
      city_code: SearchEvent::JOINVILLE,
      result_count:,
      reportable: true,
      created_at:
    )
  end
end
