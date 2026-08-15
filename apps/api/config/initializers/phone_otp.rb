# frozen_string_literal: true

otp_settings = Rails.application.config.x.berufe.otp = ActiveSupport::OrderedOptions.new

{
  resend_cooldown_seconds: ["OTP_RESEND_COOLDOWN_SECONDS", 30],
  daily_phone_limit: ["OTP_DAILY_PHONE_LIMIT", 5],
  daily_ip_limit: ["OTP_DAILY_IP_LIMIT", 20],
  challenge_ttl_seconds: ["OTP_CHALLENGE_TTL_SECONDS", 600]
}.each do |setting, (environment_name, default)|
  value = Integer(ENV.fetch(environment_name, default.to_s), 10)
  raise ArgumentError, "#{environment_name} must be a positive integer" unless value.positive?

  otp_settings[setting] = value
rescue ArgumentError
  raise ArgumentError, "#{environment_name} must be a positive integer"
end
