# frozen_string_literal: true

module Berufe
  class Environment
    class InvalidConfiguration < StandardError; end

    Config = Data.define(
      :name,
      :sms_otp_adapter,
      :media_storage_adapter,
      :llm_adapter,
      :mail_adapter,
      :openai_model,
      :product_launch_date
    )

    ENVIRONMENTS = %w[local preview staging integration production test].freeze
    SMS_OTP_ADAPTERS = {
      "local" => %w[fake infobip],
      "preview" => %w[fake],
      "staging" => %w[infobip],
      "integration" => %w[infobip],
      "production" => %w[infobip],
      "test" => %w[fake]
    }.freeze
    MEDIA_STORAGE_ADAPTERS = {
      "local" => %w[local],
      "preview" => %w[local],
      "staging" => %w[r2],
      "integration" => %w[r2],
      "production" => %w[r2],
      "test" => %w[local]
    }.freeze
    LLM_ADAPTERS = {
      "local" => %w[fake openai],
      "preview" => %w[fake openai],
      "staging" => %w[openai],
      "integration" => %w[openai],
      "production" => %w[openai],
      "test" => %w[fake]
    }.freeze
    NON_PRODUCTION_INFOBIP_ENVIRONMENTS = %w[local staging integration].freeze
    INFOBIP_TEST_PHONE_PATTERN = /\A\+55\d{2}9\d{8}\z/

    COMMON_REQUIRED = %w[
      DATABASE_URL
      DB_POOL
      RAILS_MAX_THREADS
      GOOD_JOB_EXECUTION_MODE
      GOOD_JOB_MAX_THREADS
      GOOD_JOB_QUEUES
      WEB_ORIGIN
      API_PUBLIC_URL
    ].freeze
    EXTERNAL_JOB_REQUIRED = %w[GOOD_JOB_PROBE_PORT].freeze
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
      R2_PRIVATE_BUCKET
    ].freeze
    OPENAI_REQUIRED = %w[OPENAI_API_KEY].freeze
    MAXMIND_REQUIRED = %w[MAXMIND_ACCOUNT_ID MAXMIND_LICENSE_KEY].freeze
    MAIL_ADAPTERS = %w[smtp resend].freeze
    SMTP_REQUIRED = %w[
      SMTP_ADDRESS
      SMTP_PORT
      SMTP_DOMAIN
      SMTP_USERNAME
      SMTP_PASSWORD
      SMTP_AUTHENTICATION
      SMTP_STARTTLS
      MAIL_FROM
    ].freeze
    RESEND_REQUIRED = %w[
      RESEND_API_KEY
      MAIL_FROM
    ].freeze

    DEFAULTS = {
      "development" => {
        "BERUFE_ENV" => "local",
        "SMS_OTP_ADAPTER" => "fake",
        "MEDIA_STORAGE_ADAPTER" => "local",
        "LLM_ADAPTER" => "fake",
        "MAIL_ADAPTER" => "smtp",
        "OPENAI_MODEL" => "gpt-5-mini",
        "PRODUCT_LAUNCH_DATE" => "2026-08-01"
      },
      "test" => {
        "BERUFE_ENV" => "test",
        "SMS_OTP_ADAPTER" => "fake",
        "MEDIA_STORAGE_ADAPTER" => "local",
        "LLM_ADAPTER" => "fake",
        "MAIL_ADAPTER" => "smtp",
        "OPENAI_MODEL" => "gpt-5-mini",
        "PRODUCT_LAUNCH_DATE" => "2026-08-01"
      }
    }.freeze

    def self.load!(environment: ENV, rails_environment: "development")
      values = DEFAULTS.fetch(rails_environment, {}).merge(environment.to_h)
      name = values["BERUFE_ENV"]
      sms_otp_adapter = values["SMS_OTP_ADAPTER"]
      media_storage_adapter = values["MEDIA_STORAGE_ADAPTER"]
      llm_adapter = values["LLM_ADAPTER"]
      mail_adapter = values["MAIL_ADAPTER"]
      openai_model = values["OPENAI_MODEL"].to_s.strip.presence || "gpt-5-mini"
      errors = []
      product_launch_date = parse_product_launch_date(values["PRODUCT_LAUNCH_DATE"], errors)

      errors << "BERUFE_ENV must be one of: #{ENVIRONMENTS.join(", ")}" unless ENVIRONMENTS.include?(name)
      unless mail_adapter.to_s.strip.empty? || MAIL_ADAPTERS.include?(mail_adapter)
        errors << "MAIL_ADAPTER must be one of: #{MAIL_ADAPTERS.join(", ")}"
      end

      if ENVIRONMENTS.include?(name)
        allowed_sms_otp_adapters = SMS_OTP_ADAPTERS.fetch(name)
        allowed_media_storage_adapters = MEDIA_STORAGE_ADAPTERS.fetch(name)
        allowed_llm_adapters = LLM_ADAPTERS.fetch(name)
        unless allowed_sms_otp_adapters.include?(sms_otp_adapter)
          errors << "SMS_OTP_ADAPTER must be one of: #{allowed_sms_otp_adapters.join(", ")} for #{name}"
        end
        unless allowed_media_storage_adapters.include?(media_storage_adapter)
          errors << "MEDIA_STORAGE_ADAPTER must be one of: #{allowed_media_storage_adapters.join(", ")} for #{name}"
        end
        unless allowed_llm_adapters.include?(llm_adapter)
          errors << "LLM_ADAPTER must be one of: #{allowed_llm_adapters.join(", ")} for #{name}"
        end
      end

      required = required_variables(name, sms_otp_adapter, media_storage_adapter, llm_adapter, mail_adapter, values)
      missing = required.select { |key| values[key].to_s.strip.empty? }
      errors << "missing required variables: #{missing.sort.join(", ")}" if missing.any?

      validate_infobip_configuration(name, sms_otp_adapter, values, errors)
      validate_mail_configuration(name, mail_adapter, errors)
      validate_job_configuration(name, values, errors)

      raise InvalidConfiguration, "Invalid Berufe configuration: #{errors.join("; ")}" if errors.any?

      Config.new(
        name:,
        sms_otp_adapter:,
        media_storage_adapter:,
        llm_adapter:,
        mail_adapter:,
        openai_model:,
        product_launch_date:
      )
    end

    def self.parse_product_launch_date(value, errors)
      if value.to_s.strip.empty?
        errors << "missing required variables: PRODUCT_LAUNCH_DATE"
        return
      end

      Date.iso8601(value)
    rescue Date::Error
      errors << "PRODUCT_LAUNCH_DATE must be an ISO date"
      nil
    end
    private_class_method :parse_product_launch_date

    def self.required_variables(name, sms_otp_adapter, media_storage_adapter, llm_adapter, mail_adapter, values)
      required = (name == "test") ? %w[TEST_DATABASE_URL DB_POOL] : COMMON_REQUIRED.dup
      required.concat(FAKE_OTP_REQUIRED) if sms_otp_adapter == "fake"
      required.concat(INFOBIP_REQUIRED) if sms_otp_adapter == "infobip"
      required.concat(LOCAL_STORAGE_REQUIRED) if media_storage_adapter == "local"
      required.concat(R2_REQUIRED) if media_storage_adapter == "r2"
      required.concat(OPENAI_REQUIRED) if llm_adapter == "openai"
      required.concat(MAXMIND_REQUIRED) if %w[staging integration production].include?(name)
      required.concat(DEPLOYMENT_SECRET_REQUIRED) if %w[staging integration production].include?(name)
      if %w[staging integration production].include?(name)
        required.concat(RESEND_REQUIRED) if mail_adapter == "resend"
        required.concat(SMTP_REQUIRED) if mail_adapter == "smtp"
      end
      required << "BUGSNAG_API_KEY" if name == "production"
      required.concat(EXTERNAL_JOB_REQUIRED) if name != "test" && values["GOOD_JOB_EXECUTION_MODE"] == "external"
      required
    end
    private_class_method :required_variables

    def self.validate_infobip_configuration(name, sms_otp_adapter, values, errors)
      return unless sms_otp_adapter == "infobip" && ENVIRONMENTS.include?(name)

      scope = values["INFOBIP_CREDENTIAL_SCOPE"]
      expected_scope = (name == "production") ? "production" : "integration"
      errors << "INFOBIP_CREDENTIAL_SCOPE must be #{expected_scope} for #{name}" unless scope == expected_scope

      return unless NON_PRODUCTION_INFOBIP_ENVIRONMENTS.include?(name)

      test_numbers = values["INFOBIP_TEST_NUMBERS"].to_s
      if test_numbers.strip.empty?
        errors << "missing required variables: INFOBIP_TEST_NUMBERS"
        return
      end

      parsed_numbers = test_numbers.split(",", -1).map(&:strip)
      return if parsed_numbers.all? { |phone| INFOBIP_TEST_PHONE_PATTERN.match?(phone) }

      errors << "INFOBIP_TEST_NUMBERS must contain comma-separated Brazilian E.164 mobile numbers"
    end
    private_class_method :validate_infobip_configuration

    def self.validate_mail_configuration(name, mail_adapter, errors)
      return unless %w[staging integration production].include?(name)

      errors << "MAIL_ADAPTER must be resend for #{name}" unless mail_adapter == "resend"
    end
    private_class_method :validate_mail_configuration

    def self.validate_job_configuration(name, values, errors)
      return if name == "test"

      expected = if name == "production"
        {
          "DB_POOL" => "7",
          "RAILS_MAX_THREADS" => "3",
          "GOOD_JOB_EXECUTION_MODE" => "async",
          "GOOD_JOB_MAX_THREADS" => "1",
          "GOOD_JOB_QUEUES" => "default"
        }
      else
        {
          "DB_POOL" => "5",
          "RAILS_MAX_THREADS" => "5",
          "GOOD_JOB_EXECUTION_MODE" => "external",
          "GOOD_JOB_MAX_THREADS" => "2",
          "GOOD_JOB_QUEUES" => "default"
        }
      end
      expected.each do |key, value|
        errors << "#{key} must be #{value}" unless values[key] == value
      end
    end
    private_class_method :validate_job_configuration
  end
end
