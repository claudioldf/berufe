# frozen_string_literal: true

require "json"
require "net/http"
require "timeout"
require "uri"

class InfobipOtpClient
  def initialize(base_url:, api_key:, application_id:, message_id:, sender:, request_timeout: 5, http: Net::HTTP)
    @base_url = base_url.delete_suffix("/")
    @api_key = api_key
    @application_id = application_id
    @message_id = message_id
    @sender = sender
    @request_timeout = request_timeout.to_f
    @http = http
  end

  def start_challenge(phone:)
    response = post_json(
      "/2fa/2/pin",
      applicationId: @application_id,
      messageId: @message_id,
      from: @sender,
      to: phone
    )
    payload = successful_payload(response)
    reference = payload["pinId"].to_s
    raise SmsOtp::ProviderUnavailable, "SMS OTP provider returned an invalid response" if reference.empty?

    SmsOtp::Challenge.new(reference:, status: "accepted")
  end

  def verify_challenge(reference:, code:)
    encoded_reference = URI.encode_www_form_component(reference.to_s)
    response = post_json("/2fa/2/pin/#{encoded_reference}/verify", pin: code)
    payload = successful_payload(response)
    verified = payload["verified"] == true

    SmsOtp::Verification.new(verified:, status: verified ? "verified" : "not_verified")
  end

  private

  def post_json(path, body)
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
    raise SmsOtp::ProviderUnavailable, "SMS OTP provider is unavailable"
  end

  def successful_payload(response)
    if response.code.to_i == 429
      raise SmsOtp::RateLimited.new(retry_after: response["Retry-After"])
    end

    unless response.code.to_i.between?(200, 299)
      error_class = response.code.to_i.between?(400, 499) ? SmsOtp::DeliveryRejected : SmsOtp::ProviderUnavailable
      raise error_class, "SMS OTP provider rejected the request"
    end

    JSON.parse(response.body)
  rescue JSON::ParserError
    raise SmsOtp::ProviderUnavailable, "SMS OTP provider returned an invalid response"
  end
end
