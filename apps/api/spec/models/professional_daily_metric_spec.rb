# frozen_string_literal: true

require "rails_helper"

RSpec.describe ProfessionalDailyMetric do
  include ActiveSupport::Testing::TimeHelpers

  let(:account) { UserAccount.create!(phone_e164: "+5547999997601", role: "professional", status: "active") }
  let(:profile) { ProfessionalProfile.create!(user_account: account, display_name: "Métrica Diária") }

  after { travel_back }

  it "increments the aggregate on the São Paulo local date" do
    travel_to(Time.zone.parse("2026-08-17 02:30:00 UTC")) do
      described_class.increment_profile_views!(professional_id: profile.id)
      described_class.increment_profile_views!(professional_id: profile.id)
    end

    expect(described_class.sole).to have_attributes(
      professional: profile,
      metric_date: Date.new(2026, 8, 16),
      profile_views: 2,
      whatsapp_clicks: 0,
      whatsapp_clicks_public_profile: 0,
      whatsapp_clicks_search_result: 0,
      quotes_shared: 0
    )
  end

  it "enforces non-negative counters and the WhatsApp source-total invariant" do
    metric = described_class.create!(professional: profile, metric_date: Date.new(2026, 8, 17))

    metric.profile_views = -1
    expect(metric).not_to be_valid
    expect(metric.errors).to have_key(:profile_views)

    metric.assign_attributes(
      profile_views: 0,
      whatsapp_clicks: 2,
      whatsapp_clicks_public_profile: 1,
      whatsapp_clicks_search_result: 0
    )
    expect(metric).not_to be_valid
    expect(metric.errors).to have_key(:whatsapp_clicks)

    expect do
      metric.update_columns(
        whatsapp_clicks: 2,
        whatsapp_clicks_public_profile: 1,
        whatsapp_clicks_search_result: 0
      )
    end.to raise_error(ActiveRecord::StatementInvalid)
  end

  it "atomically increments the WhatsApp total with exactly one source on the São Paulo date" do
    occurred_at = Time.zone.parse("2026-08-17 02:30:00 UTC")

    described_class.increment_whatsapp_clicks!(
      professional_id: profile.id,
      source: "public_profile",
      occurred_at:
    )
    described_class.increment_whatsapp_clicks!(
      professional_id: profile.id,
      source: "search_result",
      occurred_at:
    )

    expect(described_class.sole).to have_attributes(
      metric_date: Date.new(2026, 8, 16),
      whatsapp_clicks: 2,
      whatsapp_clicks_public_profile: 1,
      whatsapp_clicks_search_result: 1
    )
    expect do
      described_class.increment_whatsapp_clicks!(
        professional_id: profile.id,
        source: "unknown"
      )
    end.to raise_error(KeyError)
  end

  it "increments each quote-share attempt on the São Paulo local date" do
    occurred_at = Time.zone.parse("2026-08-17 02:30:00 UTC")

    described_class.increment_quote_shares!(professional_id: profile.id, occurred_at:)
    described_class.increment_quote_shares!(professional_id: profile.id, occurred_at:)

    expect(described_class.sole).to have_attributes(
      metric_date: Date.new(2026, 8, 16),
      quotes_shared: 2,
      profile_views: 0,
      whatsapp_clicks: 0
    )
  end
end
