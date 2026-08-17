# frozen_string_literal: true

require_relative "../../app/services/sms_otp"
require_relative "../../app/services/fake_sms_otp_client"

RSpec.describe FakeSmsOtpClient do
  subject(:client) { described_class.new(code: "123456") }

  it "starts and verifies a synthetic challenge" do
    challenge = client.start_challenge(phone: "+5547999999999")

    expect(challenge.status).to eq("accepted")
    expect(client.verify_challenge(reference: challenge.reference, code: "123456").verified).to be(true)
  end

  it "rejects an incorrect code or unknown reference" do
    challenge = client.start_challenge(phone: "+5547999999999")

    expect(client.verify_challenge(reference: challenge.reference, code: "000000").verified).to be(false)
    expect(client.verify_challenge(reference: "provider-reference", code: "123456").verified).to be(false)
  end
end
