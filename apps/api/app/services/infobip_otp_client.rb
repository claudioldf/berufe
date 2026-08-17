# frozen_string_literal: true

require "json"
require "net/http"
require "timeout"
require "uri"

class InfobipOtpClient
  def initialize(
    base_url:,
    api_key:,
    application_id:,
    message_id:,
    sender:,
    request_timeout: 5,
    allowed_phone_numbers: nil,
    logger: nil,
    http: Net::HTTP
  )
    @base_url = base_url.delete_suffix("/")
    @api_key = api_key
    @application_id = application_id
    @message_id = message_id
    @sender = sender
    @request_timeout = request_timeout.to_f
    @allowed_phone_numbers = allowed_phone_numbers
    @logger = logger
    @http = http
  end

  def start_challenge(phone:)
    enforce_allowed_phone!(phone)
    response = post_json(
      "/2fa/2/pin",
      operation: "start_challenge",
      applicationId: @application_id,
      messageId: @message_id,
      from: @sender,
      to: phone
    )
    payload = successful_payload(response, operation: "start_challenge")
    reference = payload["pinId"].to_s
    if reference.empty?
      log_outcome(event: "infobip_otp_request_failed", operation: "start_challenge", http_status: response.code.to_i)
      raise SmsOtp::ProviderUnavailable, "SMS OTP provider returned an invalid response"
    end

    log_outcome(event: "infobip_otp_request_accepted", operation: "start_challenge", http_status: response.code.to_i)
    SmsOtp::Challenge.new(reference:, status: "accepted")
  end

  def verify_challenge(reference:, code:)
    encoded_reference = URI.encode_www_form_component(reference.to_s)
    response = post_json("/2fa/2/pin/#{encoded_reference}/verify", operation: "verify_challenge", pin: code)
    payload = successful_payload(response, operation: "verify_challenge")
    verified = payload["verified"] == true

    log_outcome(event: "infobip_otp_request_accepted", operation: "verify_challenge", http_status: response.code.to_i)
    SmsOtp::Verification.new(verified:, status: verified ? "verified" : "not_verified")
  end

  private

  def enforce_allowed_phone!(phone)
    return unless @allowed_phone_numbers
    return if @allowed_phone_numbers.include?(phone)

    log_outcome(event: "infobip_otp_recipient_blocked", operation: "start_challenge")
    raise SmsOtp::DeliveryRejected, "SMS OTP recipient is not allowed in this environment"
  end

  def post_json(path, operation:, **body)
    uri = URI.parse("#{@base_url}#{path}")
    request = Net::HTTP::Post.new(uri)
    request["Authorization"] = "App #{@api_key}"
    request["Accept"] = "application/json"
    request["Content-Type"] = "application/json"
    request.body = JSON.generate(body)

    @http.start(
      uri.host,
      uri.port,
      use_ssl: uri.scheme == "https",
      open_timeout: @request_timeout,
      read_timeout: @request_timeout
    ) { |connection| connection.request(request) }
  rescue IOError, SocketError, SystemCallError, Timeout::Error
    log_outcome(event: "infobip_otp_request_failed", operation:)
    raise SmsOtp::ProviderUnavailable, "SMS OTP provider is unavailable"
  end

  def successful_payload(response, operation:)
    if response.code.to_i == 429
      log_outcome(event: "infobip_otp_request_failed", operation:, http_status: response.code.to_i)
      raise SmsOtp::RateLimited.new(retry_after: response["Retry-After"])
    end

    unless response.code.to_i.between?(200, 299)
      log_outcome(event: "infobip_otp_request_failed", operation:, http_status: response.code.to_i)
      error_class = provider_error_class(response.code.to_i)
      raise error_class, "SMS OTP provider rejected the request"
    end

    JSON.parse(response.body)
  rescue JSON::ParserError
    log_outcome(event: "infobip_otp_request_failed", operation:, http_status: response.code.to_i)
    raise SmsOtp::ProviderUnavailable, "SMS OTP provider returned an invalid response"
  end

  def provider_error_class(http_status)
    return SmsOtp::ProviderUnavailable if [401, 403].include?(http_status)
    return SmsOtp::DeliveryRejected if http_status.between?(400, 499)

    SmsOtp::ProviderUnavailable
  end

  def log_outcome(event:, operation:, http_status: nil)
    return unless @logger

    payload = {event:, provider: "infobip", operation:}
    payload[:http_status] = http_status if http_status
    request_id = Current.request_id if defined?(Current)
    payload[:request_id] = request_id unless request_id.to_s.empty?
    @logger.info(payload)
  end
end
