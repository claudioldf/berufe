# frozen_string_literal: true

require "rails_helper"

RSpec.describe OtpChallenge, type: :model do
  it "stores only a token digest and encrypted provider/phone values" do
    challenge, public_token = described_class.issue!(
      phone_e164: "+5547999991111",
      provider_reference: "provider-reference",
      expires_at: 10.minutes.from_now
    )
    persisted_attributes = challenge.attributes.slice(
      "public_token_digest",
      "phone_e164_ciphertext",
      "infobip_challenge_id_ciphertext"
    )

    expect(public_token).to match(/\A[A-Za-z0-9_-]{43}\z/)
    expect(persisted_attributes.fetch("public_token_digest")).to eq(
      OtpSecurityDigest.call(purpose: "challenge_token", value: public_token)
    )
    expect(persisted_attributes.values).not_to include(public_token, "+5547999991111", "provider-reference")
    expect(challenge.phone_e164).to eq("+5547999991111")
    expect(challenge.provider_reference).to eq("provider-reference")
  end

  it "stores an encrypted email and a keyed code digest without persisting either plaintext value" do
    challenge, public_token = described_class.issue_email!(
      email: "ana@example.com",
      code: "123456",
      expires_at: 10.minutes.from_now
    )

    expect(challenge).to be_email
    expect(challenge.email).to eq("ana@example.com")
    expect(challenge.valid_email_code?(public_token:, code: "123456")).to be(true)
    expect(challenge.valid_email_code?(public_token:, code: "000000")).to be(false)
    expect(challenge.attributes.to_json).not_to include("ana@example.com", "123456", public_token)
  end
end
