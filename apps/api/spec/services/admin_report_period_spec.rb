# frozen_string_literal: true

require "rails_helper"

RSpec.describe Admin::Reports::Period do
  it "uses Sao Paulo local-day boundaries for trailing windows" do
    generated_at = Time.iso8601("2026-08-18T02:30:00Z")
    period = described_class.new(key: "last_7_days", generated_at:)

    expect(period.start_date).to eq(Date.new(2026, 8, 11))
    expect(period.end_date).to eq(Date.new(2026, 8, 17))
    expect(period.start_at.iso8601).to eq("2026-08-11T00:00:00-03:00")
    expect(period.end_at.iso8601).to eq("2026-08-18T00:00:00-03:00")
  end

  it "truncates since-launch reporting to the retained 730 local dates" do
    reporting = Rails.configuration.x.berufe.reporting
    previous_launch = reporting.product_launch_date
    reporting.product_launch_date = Date.new(2020, 1, 1)

    period = described_class.new(
      key: "since_launch",
      generated_at: Time.iso8601("2026-08-18T15:00:00Z")
    )

    expect(period.start_date).to eq(Date.new(2024, 8, 19))
    expect(period.to_h).to include(label: "Últimos 24 meses", short_label: "24 meses", truncated: true)
  ensure
    reporting.product_launch_date = previous_launch
  end
end
