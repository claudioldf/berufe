# frozen_string_literal: true

require "rails_helper"

RSpec.describe SmsOtpClient do
  let(:settings_class) { Data.define(:name, :sms_otp_adapter, :media_storage_adapter) }

  it "builds an allowlisted Infobip client outside production" do
    settings = settings_class.new(name: "local", sms_otp_adapter: "infobip", media_storage_adapter: "local")
    environment = {
      "INFOBIP_BASE_URL" => "https://example.api.infobip.com",
      "INFOBIP_API_KEY" => "private-api-key",
      "INFOBIP_2FA_APPLICATION_ID" => "application-id",
      "INFOBIP_2FA_MESSAGE_ID" => "message-id",
      "INFOBIP_SENDER" => "Berufe",
      "INFOBIP_TEST_NUMBERS" => "+5547999999999, +5547888888888"
    }
    client = instance_double(InfobipOtpClient)
    allow(InfobipOtpClient).to receive(:new).and_return(client)

    expect(described_class.build(settings:, environment:)).to equal(client)
    expect(InfobipOtpClient).to have_received(:new).with(
      hash_including(
        base_url: "https://example.api.infobip.com",
        allowed_phone_numbers: ["+5547999999999", "+5547888888888"],
        logger: Rails.logger
      )
    )
  end

  it "leaves production recipients unrestricted" do
    settings = settings_class.new(name: "production", sms_otp_adapter: "infobip", media_storage_adapter: "r2")
    environment = {
      "INFOBIP_BASE_URL" => "https://example.api.infobip.com",
      "INFOBIP_API_KEY" => "private-api-key",
      "INFOBIP_2FA_APPLICATION_ID" => "application-id",
      "INFOBIP_2FA_MESSAGE_ID" => "message-id",
      "INFOBIP_SENDER" => "Berufe"
    }
    allow(InfobipOtpClient).to receive(:new).and_call_original

    described_class.build(settings:, environment:)

    expect(InfobipOtpClient).to have_received(:new).with(hash_including(allowed_phone_numbers: nil))
  end

  it "builds the fake client only for test settings" do
    settings = settings_class.new(name: "test", sms_otp_adapter: "fake", media_storage_adapter: "local")

    expect(described_class.build(settings:, environment: {"FAKE_SMS_OTP_CODE" => "123456"}))
      .to be_a(FakeSmsOtpClient)
  end
end
