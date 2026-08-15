# frozen_string_literal: true

require_relative "../../../lib/berufe/environment"

RSpec.describe Berufe::Environment do
  def local_environment
    {
      "BERUFE_ENV" => "local",
      "SMS_OTP_ADAPTER" => "fake",
      "MEDIA_STORAGE_ADAPTER" => "local",
      "DATABASE_URL" => "postgresql://local.example/berufe",
      "DB_POOL" => "5",
      "WEB_ORIGIN" => "http://localhost:3000",
      "API_PUBLIC_URL" => "http://localhost:3001",
      "FAKE_SMS_OTP_CODE" => "123456",
      "LOCAL_STORAGE_ROOT" => "/tmp/berufe"
    }
  end

  def production_environment
    local_environment.merge(
      "BERUFE_ENV" => "production",
      "SMS_OTP_ADAPTER" => "infobip",
      "MEDIA_STORAGE_ADAPTER" => "r2",
      "SECRET_KEY_BASE" => "server-secret",
      "BUGSNAG_API_KEY" => "bugsnag-secret",
      "INFOBIP_BASE_URL" => "https://example.api.infobip.com",
      "INFOBIP_API_KEY" => "infobip-secret",
      "INFOBIP_2FA_APPLICATION_ID" => "application-id",
      "INFOBIP_2FA_MESSAGE_ID" => "message-id",
      "INFOBIP_SENDER" => "Berufe",
      "INFOBIP_CREDENTIAL_SCOPE" => "production",
      "R2_ENDPOINT" => "https://account.r2.cloudflarestorage.com",
      "R2_ACCESS_KEY_ID" => "r2-access-key",
      "R2_SECRET_ACCESS_KEY" => "r2-secret",
      "R2_PUBLIC_BUCKET" => "public-media",
      "R2_PRIVATE_BUCKET" => "private-media"
    )
  end

  it "selects safe adapters for local development" do
    config = described_class.load!(environment: local_environment)

    expect(config.name).to eq("local")
    expect(config.sms_otp_adapter).to eq("fake")
    expect(config.media_storage_adapter).to eq("local")
  end

  it "defaults Rails test processes to fake and local adapters" do
    environment = {
      "TEST_DATABASE_URL" => "postgresql://test.example/berufe",
      "DB_POOL" => "5",
      "FAKE_SMS_OTP_CODE" => "123456",
      "LOCAL_STORAGE_ROOT" => "/tmp/berufe-test"
    }

    config = described_class.load!(environment:, rails_environment: "test")

    expect(config.name).to eq("test")
    expect(config.sms_otp_adapter).to eq("fake")
    expect(config.media_storage_adapter).to eq("local")
  end

  it "rejects live adapters in local development" do
    environment = local_environment.merge("SMS_OTP_ADAPTER" => "infobip")

    expect { described_class.load!(environment:) }
      .to raise_error(described_class::InvalidConfiguration, /SMS_OTP_ADAPTER must be fake for local/)
  end

  it "requires live purpose-specific adapters and credentials in production" do
    config = described_class.load!(environment: production_environment, rails_environment: "production")

    expect(config.name).to eq("production")
    expect(config.sms_otp_adapter).to eq("infobip")
    expect(config.media_storage_adapter).to eq("r2")
  end

  it "requires a separate scoped profile and allowlist for integration checks" do
    environment = production_environment.merge(
      "BERUFE_ENV" => "integration",
      "INFOBIP_CREDENTIAL_SCOPE" => "production",
      "INFOBIP_TEST_NUMBERS" => ""
    )

    expect { described_class.load!(environment:, rails_environment: "production") }
      .to raise_error(described_class::InvalidConfiguration, /must be integration.*INFOBIP_TEST_NUMBERS/)
  end

  it "reports variable names without leaking their values" do
    environment = production_environment.merge("INFOBIP_API_KEY" => "top-secret-value", "R2_SECRET_ACCESS_KEY" => "")

    expect { described_class.load!(environment:, rails_environment: "production") }
      .to raise_error(described_class::InvalidConfiguration) { |error|
        expect(error.message).to include("R2_SECRET_ACCESS_KEY")
        expect(error.message).not_to include("top-secret-value")
      }
  end
end
