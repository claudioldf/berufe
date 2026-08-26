# frozen_string_literal: true

require "rails_helper"

RSpec.describe PublicSearchRateLimiter do
  it "allows forty searches per IP in an hour without storing the address" do
    now = Time.zone.parse("2026-08-25 10:30:00")
    40.times { described_class.new.check_and_increment!(ip_address: "203.0.113.10", now:) }

    expect {
      described_class.new.check_and_increment!(ip_address: "203.0.113.10", now:)
    }.to raise_error(described_class::RateLimited) do |error|
      expect(error.retry_after).to eq(30.minutes.to_i)
    end
    counter = PublicSearchRateLimitCounter.sole
    expect(counter.request_count).to eq(40)
    expect(counter.subject_digest).to match(/\A[0-9a-f]{64}\z/)
    expect(counter.attributes.to_json).not_to include("203.0.113.10")
  end
end
