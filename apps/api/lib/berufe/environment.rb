# frozen_string_literal: true

module Berufe
  class Environment
    class InvalidConfiguration < StandardError; end

    Config = Data.define(:name, :sms_otp_adapter, :media_storage_adapter)

    ENVIRONMENTS = %w[local preview staging integration production test].freeze
    ADAPTERS = {
      "local" => ["fake", "local"],
      "preview" => ["fake", "local"],
      "staging" => ["fake", "r2"],
      "integration" => ["infobip", "r2"],
      "production" => ["infobip", "r2"],
      "test" => ["fake", "local"]
    }.freeze

    COMMON_REQUIRED = %w[
      DATABASE_URL
      DB_POOL
      RAILS_MAX_THREADS
      GOOD_JOB_EXECUTION_MODE
      GOOD_JOB_MAX_THREADS
      GOOD_JOB_QUEUES
      GOOD_JOB_PROBE_PORT
      WEB_ORIGIN
      API_PUBLIC_URL
    ].freeze
    FAKE_OTP_REQUIRED = %w[FAKE_SMS_OTP_CODE].freeze
    LOCAL_STORAGE_REQUIRED = %w[LOCAL_STORAGE_ROOT].freeze
    DEPLOYMENT_SECRET_REQUIRED = %w[SECRET_KEY_BASE].freeze
    INFOBIP_REQUIRED = %w[
      INFOBIP_BASE_URL
      INFOBIP_API_KEY
      INFOBIP_2FA_APPLICATION_ID
      INFOBIP_2FA_MESSAGE_ID
      INFOBIP_SENDER
    ].freeze
    R2_REQUIRED = %w[
      R2_ENDPOINT
      R2_ACCESS_KEY_ID
      R2_SECRET_ACCESS_KEY
      R2_PUBLIC_BUCKET
      R2_PRIVATE_BUCKET
    ].freeze

    DEFAULTS = {
      "development" => {
        "BERUFE_ENV" => "local",
        "SMS_OTP_ADAPTER" => "fake",
        "MEDIA_STORAGE_ADAPTER" => "local"
      },
      "test" => {
        "BERUFE_ENV" => "test",
        "SMS_OTP_ADAPTER" => "fake",
        "MEDIA_STORAGE_ADAPTER" => "local"
      }
    }.freeze

    def self.load!(environment: ENV, rails_environment: "development")
      values = DEFAULTS.fetch(rails_environment, {}).merge(environment.to_h)
      name = values["BERUFE_ENV"]
      sms_otp_adapter = values["SMS_OTP_ADAPTER"]
      media_storage_adapter = values["MEDIA_STORAGE_ADAPTER"]

      errors = []
      errors << "BERUFE_ENV must be one of: #{ENVIRONMENTS.join(", ")}" unless ENVIRONMENTS.include?(name)

      expected_adapters = ADAPTERS[name]
      if expected_adapters
        expected_sms_otp, expected_media_storage = expected_adapters
        errors << "SMS_OTP_ADAPTER must be #{expected_sms_otp} for #{name}" unless sms_otp_adapter == expected_sms_otp
        errors << "MEDIA_STORAGE_ADAPTER must be #{expected_media_storage} for #{name}" unless media_storage_adapter == expected_media_storage
      end

      required = required_variables(name, sms_otp_adapter, media_storage_adapter)
      missing = required.select { |key| values[key].to_s.strip.empty? }
      errors << "missing required variables: #{missing.sort.join(", ")}" if missing.any?

      validate_credential_scope(name, values, errors)
      validate_job_configuration(name, values, errors)

      raise InvalidConfiguration, "Invalid Berufe configuration: #{errors.join("; ")}" if errors.any?

      Config.new(name:, sms_otp_adapter:, media_storage_adapter:)
    end

    def self.required_variables(name, sms_otp_adapter, media_storage_adapter)
      required = (name == "test") ? %w[TEST_DATABASE_URL DB_POOL] : COMMON_REQUIRED.dup
      required.concat(FAKE_OTP_REQUIRED) if sms_otp_adapter == "fake"
      required.concat(INFOBIP_REQUIRED) if sms_otp_adapter == "infobip"
      required.concat(LOCAL_STORAGE_REQUIRED) if media_storage_adapter == "local"
      required.concat(R2_REQUIRED) if media_storage_adapter == "r2"
      required.concat(DEPLOYMENT_SECRET_REQUIRED) if %w[staging integration production].include?(name)
      required << "BUGSNAG_API_KEY" if name == "production"
      required
    end
    private_class_method :required_variables

    def self.validate_credential_scope(name, values, errors)
      return unless %w[integration production].include?(name)

      scope = values["INFOBIP_CREDENTIAL_SCOPE"]
      errors << "INFOBIP_CREDENTIAL_SCOPE must be #{name}" unless scope == name

      if name == "integration" && values["INFOBIP_TEST_NUMBERS"].to_s.strip.empty?
        errors << "missing required variables: INFOBIP_TEST_NUMBERS"
      end
    end
    private_class_method :validate_credential_scope

    def self.validate_job_configuration(name, values, errors)
      return if name == "test"

      expected = {
        "DB_POOL" => "5",
        "RAILS_MAX_THREADS" => "5",
        "GOOD_JOB_EXECUTION_MODE" => "external",
        "GOOD_JOB_MAX_THREADS" => "2",
        "GOOD_JOB_QUEUES" => "default"
      }
      expected.each do |key, value|
        errors << "#{key} must be #{value}" unless values[key] == value
      end
    end
    private_class_method :validate_job_configuration
  end
end
