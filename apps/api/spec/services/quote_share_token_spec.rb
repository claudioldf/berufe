# frozen_string_literal: true

require "rails_helper"

RSpec.describe QuoteShareToken do
  it "derives a stable high-entropy bearer and a separate fixed-length digest" do
    quote_id = SecureRandom.uuid

    token = described_class.issue(quote_id)

    expect(token).to match(/\Abq_[A-Za-z0-9_-]{43}\z/)
    expect(described_class.issue(quote_id)).to eq(token)
    expect(described_class.issue(SecureRandom.uuid)).not_to eq(token)
    expect(described_class.digest(token)).to match(/\A[0-9a-f]{64}\z/)
    expect(described_class.digest(token)).not_to include(token)
    expect(described_class.matches?(quote_id:, token:)).to be(true)
    expect(described_class.matches?(quote_id:, token: "bq_#{"A" * 43}")).to be(false)
    expect(described_class.valid?("malformed")).to be(false)
  end
end
