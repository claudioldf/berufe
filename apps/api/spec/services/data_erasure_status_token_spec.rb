# frozen_string_literal: true

require "rails_helper"

RSpec.describe DataErasureStatusToken do
  it "issues an opaque token that can be digested and encrypted without storing it in plaintext" do
    token = described_class.issue

    expect(token).to match(described_class::PATTERN)
    expect(described_class.digest(token)).to match(/\A[0-9a-f]{64}\z/)
    expect(described_class.decrypt(described_class.encrypt(token))).to eq(token)
  end

  it "rejects malformed and tampered values" do
    expect(described_class.valid?("not-a-token")).to be(false)
    expect(described_class.decrypt("tampered")).to be_nil
  end
end
