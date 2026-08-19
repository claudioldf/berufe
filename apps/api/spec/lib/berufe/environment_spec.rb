# frozen_string_literal: true

require_relative "../../../lib/berufe/environment"

RSpec.describe Berufe::Environment do
  def common_environment
    {
      "DATABASE_URL" => "postgresql://local.example/berufe",
      "DB_POOL" => "5",
      "RAILS_MAX_THREADS" => "5",
      "GOOD_JOB_EXECUTION_MODE" => "external",
      "GOOD_JOB_MAX_THREADS" => "2",
      "GOOD_JOB_QUEUES" => "default",
      "GOOD_JOB_PROBE_PORT" => "7001",
      "WEB_ORIGIN" => "http://localhost:3000",
      "API_PUBLIC_URL" => "http://localhost:3001",
      "PRODUCT_LAUNCH_DATE" => "2026-08-01"
    }
  end

  def infobip_environment(name:, media_storage:)
    environment = common_environment.merge(
      "BERUFE_ENV" => name,
      "SMS_OTP_ADAPTER" => "infobip",
      "MEDIA_STORAGE_ADAPTER" => media_storage,
      "INFOBIP_BASE_URL" => "https://example.api.infobip.com",
      "INFOBIP_API_KEY" => "infobip-secret",
      "INFOBIP_2FA_APPLICATION_ID" => "application-id",
      "INFOBIP_2FA_MESSAGE_ID" => "message-id",
      "INFOBIP_SENDER" => "Berufe",
      "INFOBIP_CREDENTIAL_SCOPE" => (name == "production") ? "production" : "integration",
      "INFOBIP_TEST_NUMBERS" => (name == "production") ? "" : "+5547999999999",
      "LOCAL_STORAGE_ROOT" => "/tmp/berufe"
    )
    if media_storage == "r2"
      environment.merge!(
        "R2_ENDPOINT" => "https://account.r2.cloudflarestorage.com",
        "R2_ACCESS_KEY_ID" => "r2-access-key",
        "R2_SECRET_ACCESS_KEY" => "r2-secret",
        "R2_PUBLIC_BUCKET" => "public-media",
        "R2_PRIVATE_BUCKET" => "private-media"
      )
    end
    environment["SECRET_KEY_BASE"] = "server-secret" if %w[staging integration production].include?(name)
    environment["BUGSNAG_API_KEY"] = "bugsnag-secret" if name == "production"
    environment
  end

  def fake_environment(name: "local")
    common_environment.merge(
      "BERUFE_ENV" => name,
      "SMS_OTP_ADAPTER" => "fake",
      "MEDIA_STORAGE_ADAPTER" => "local",
      "FAKE_SMS_OTP_CODE" => "123456",
      "LOCAL_STORAGE_ROOT" => "/tmp/berufe-#{name}"
    )
  end

  def local_environment
    infobip_environment(name: "local", media_storage: "local")
  end

  def production_environment
    infobip_environment(name: "production", media_storage: "r2")
  end

  it "supports explicit fake and restricted Infobip adapters in local development" do
    fake_config = described_class.load!(environment: fake_environment)
    infobip_config = described_class.load!(environment: local_environment)

    expect(fake_config).to have_attributes(
      name: "local",
      sms_otp_adapter: "fake",
      media_storage_adapter: "local",
      product_launch_date: Date.new(2026, 8, 1)
    )
    expect(infobip_config).to have_attributes(
      name: "local",
      sms_otp_adapter: "infobip",
      media_storage_adapter: "local"
    )
  end

  it "uses fake delivery and local storage for previews" do
    config = described_class.load!(environment: fake_environment(name: "preview"))

    expect(config).to have_attributes(
      name: "preview",
      sms_otp_adapter: "fake",
      media_storage_adapter: "local"
    )
  end

  it "selects restricted Infobip for staging and integration and production Infobip for production" do
    {
      "staging" => "r2",
      "integration" => "r2",
      "production" => "r2"
    }.each do |name, media_storage|
      environment = infobip_environment(name:, media_storage:)
      config = described_class.load!(environment:, rails_environment: (name == "production") ? "production" : "development")

      expect(config.name).to eq(name)
      expect(config.sms_otp_adapter).to eq("infobip")
      expect(config.media_storage_adapter).to eq(media_storage)
    end
  end

  it "defaults Rails development processes to fake delivery and local storage" do
    environment = common_environment.merge(
      "FAKE_SMS_OTP_CODE" => "123456",
      "LOCAL_STORAGE_ROOT" => "/tmp/berufe-local"
    )

    config = described_class.load!(environment:)

    expect(config).to have_attributes(
      name: "local",
      sms_otp_adapter: "fake",
      media_storage_adapter: "local"
    )
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

  it "requires integration-scoped credentials and an allowlist outside production" do
    environment = local_environment.merge(
      "INFOBIP_CREDENTIAL_SCOPE" => "production",
      "INFOBIP_TEST_NUMBERS" => ""
    )

    expect { described_class.load!(environment:) }
      .to raise_error(described_class::InvalidConfiguration, /must be integration for local.*INFOBIP_TEST_NUMBERS/)
  end

  it "rejects malformed non-production allowlists without leaking their values" do
    private_value = "47999999999"
    environment = local_environment.merge("INFOBIP_TEST_NUMBERS" => "+5547999999999,#{private_value}")

    expect { described_class.load!(environment:) }
      .to raise_error(described_class::InvalidConfiguration) { |error|
        expect(error.message).to include("INFOBIP_TEST_NUMBERS must contain comma-separated Brazilian E.164 mobile numbers")
        expect(error.message).not_to include(private_value)
      }
  end

  it "does not apply the non-production allowlist to production" do
    config = described_class.load!(environment: production_environment, rails_environment: "production")

    expect(config.name).to eq("production")
    expect(config.sms_otp_adapter).to eq("infobip")
  end

  it "keeps the foundation on the documented database and worker budgets" do
    environment = local_environment.merge("GOOD_JOB_QUEUES" => "default,mailers", "GOOD_JOB_MAX_THREADS" => "4")

    expect { described_class.load!(environment:) }
      .to raise_error(described_class::InvalidConfiguration, /GOOD_JOB_MAX_THREADS must be 2.*GOOD_JOB_QUEUES must be default/)
  end

  it "requires a valid explicit product launch date in deployed environments" do
    environment = production_environment.merge("PRODUCT_LAUNCH_DATE" => "not-a-date")

    expect { described_class.load!(environment:, rails_environment: "production") }
      .to raise_error(described_class::InvalidConfiguration, /PRODUCT_LAUNCH_DATE must be an ISO date/)
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
