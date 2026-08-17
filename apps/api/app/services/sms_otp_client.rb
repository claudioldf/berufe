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
        request_timeout: environment.fetch("INFOBIP_REQUEST_TIMEOUT_SECONDS", "5")
      )
    else
      raise ArgumentError, "Unsupported SMS OTP adapter"
    end
  end
end
