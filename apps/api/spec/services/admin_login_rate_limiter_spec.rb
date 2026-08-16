# frozen_string_literal: true

require "rails_helper"

RSpec.describe AdminLoginRateLimiter do
  let(:service) { described_class.new }
  let(:now) { Time.zone.parse("2026-08-15 12:07:00 UTC") }

  it "uses fixed database windows without storing the email or source address" do
    4.times do
      service.register_failure!(email: "admin@example.com", ip_address: "203.0.113.9", now:)
    end

    counters = AdminLoginAttemptCounter.order(:scope)
    expect(counters.pluck(:scope, :attempt_count)).to eq([["email", 4], ["ip", 4]])
    expect(counters.pluck(:window_started_at).uniq).to eq([Time.zone.parse("2026-08-15 12:00:00 UTC")])
    expect(counters.pluck(:subject_digest)).to all(match(/\A[0-9a-f]{64}\z/))
    expect(counters.to_json).not_to include("admin@example.com", "203.0.113.9")
  end

  it "limits the fifth email failure and reports the remaining window" do
    4.times do
      service.register_failure!(email: "admin@example.com", ip_address: "203.0.113.9", now:)
    end

    expect do
      service.register_failure!(email: "admin@example.com", ip_address: "203.0.113.9", now:)
    end.to raise_error(described_class::RateLimited) { |error|
      expect(error.retry_after).to eq(8.minutes.to_i)
    }
  end

  it "clears the current email counter after a successful login without clearing the IP counter" do
    service.register_failure!(email: "admin@example.com", ip_address: "203.0.113.9", now:)

    service.clear_email!(email: "admin@example.com", now:)

    expect(AdminLoginAttemptCounter.where(scope: "email")).to be_empty
    expect(AdminLoginAttemptCounter.where(scope: "ip").pick(:attempt_count)).to eq(1)
  end
end
