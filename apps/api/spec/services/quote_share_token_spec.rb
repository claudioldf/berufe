# frozen_string_literal: true

require "rails_helper"

RSpec.describe QuoteShareToken do
  it "issues an unpredictable bearer with a separate fixed-length digest" do
    token = described_class.issue

    expect(token).to match(/\Abq_[A-Za-z0-9_-]{43}\z/)
    expect(described_class.issue).not_to eq(token)
    expect(described_class.digest(token)).to match(/\A[0-9a-f]{64}\z/)
    expect(described_class.digest(token)).not_to include(token)
    expect(described_class.valid?("malformed")).to be(false)
  end

  it "recovers the owner's copy from its ciphertext and refuses a tampered one" do
    token = described_class.issue
    ciphertext = described_class.encrypt(token)

    expect(ciphertext).not_to include(token)
    expect(described_class.decrypt(ciphertext)).to eq(token)
    expect(described_class.decrypt(nil)).to be_nil
    expect(described_class.decrypt("not-a-message")).to be_nil
  end
end
