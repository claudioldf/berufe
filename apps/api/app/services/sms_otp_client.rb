# frozen_string_literal: true

module SmsOtpClient
  def self.build(settings: Rails.configuration.x.berufe.environment, environment: ENV)
    case settings.sms_otp_adapter
    when "fake"
      FakeSmsOtpClient.new(code: environment.fetch("FAKE_SMS_OTP_CODE"))
    when "infobip"
      InfobipOtpClient.new(
        base_url: environment.fetch("INFOBIP_BASE_URL"),
        api_key: environment.fetch("INFOBIP_API_KEY"),
        application_id: environment.fetch("INFOBIP_2FA_APPLICATION_ID"),
        message_id: environment.fetch("INFOBIP_2FA_MESSAGE_ID"),
        sender: environment.fetch("INFOBIP_SENDER"),
        request_timeout: environment.fetch("INFOBIP_REQUEST_TIMEOUT_SECONDS", "5"),
        allowed_phone_numbers: allowed_phone_numbers(settings:, environment:),
        logger: Rails.logger
      )
    else
      raise ArgumentError, "Unsupported SMS OTP adapter"
    end
  end

  def self.allowed_phone_numbers(settings:, environment:)
    return if settings.name == "production"

    environment.fetch("INFOBIP_TEST_NUMBERS").split(",").map(&:strip).freeze
  end
  private_class_method :allowed_phone_numbers
end
