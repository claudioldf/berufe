# frozen_string_literal: true

require "json"
require "net/http"
require "timeout"
require "uri"

module Berufe
  # ActionMailer delivery method for Resend's HTTP API
  # (https://resend.com/docs/api-reference/emails/send-email). Registered
  # directly on ActionMailer::Base by config/environments/production.rb when
  # MAIL_ADAPTER=resend (not through config.action_mailer.resend_settings —
  # the ActionMailer railtie applies that before any config/initializers/*.rb
  # runs, which is too early to have registered this delivery method).
  #
  # Exists because Railway blocks outbound SMTP below its Pro plan, so the
  # SMTP path to smtp.resend.com:587 times out (Net::OpenTimeout) in
  # deployed environments. Resend's HTTP API is unaffected.
  class ResendMailClient
    DEFAULT_BASE_URL = "https://api.resend.com"
    DEFAULT_REQUEST_TIMEOUT = 10

    def initialize(settings)
      settings = settings.to_h
      @api_key = settings.fetch(:api_key)
      @base_url = settings.fetch(:base_url, DEFAULT_BASE_URL).to_s.delete_suffix("/")
      @request_timeout = settings.fetch(:request_timeout, DEFAULT_REQUEST_TIMEOUT).to_f
      # Not resolved from Rails.logger here: this settings hash is built once,
      # at boot, before Rails.logger is ready, and reused (frozen) for every
      # delivery for the life of the process — see log_outcome.
      @logger = settings[:logger]
      @http = settings.fetch(:http, Net::HTTP)
    end

    def deliver!(mail)
      response = post_json(payload_for(mail), idempotency_key: mail.message_id)
      handle_response(response)
      mail
    end

    private

    def payload_for(mail)
      body = {
        from: from_address(mail),
        to: Array(mail.to),
        subject: mail.subject.to_s
      }
      html = mail.html_part&.decoded
      text = mail.text_part&.decoded
      if html || text
        body[:html] = html if html
        body[:text] = text if text
      elsif mail.mime_type == "text/html"
        body[:html] = mail.body.decoded
      else
        body[:text] = mail.body.decoded
      end
      body
    end

    def from_address(mail)
      mail[:from]&.formatted&.first || Array(mail.from).first
    end

    def post_json(body, idempotency_key:)
      uri = URI.parse("#{@base_url}/emails")
      request = Net::HTTP::Post.new(uri)
      request["Authorization"] = "Bearer #{@api_key}"
      request["Accept"] = "application/json"
      request["Content-Type"] = "application/json"
      request["Idempotency-Key"] = idempotency_key unless idempotency_key.to_s.empty?
      request.body = JSON.generate(body)

      @http.start(
        uri.host,
        uri.port,
        use_ssl: uri.scheme == "https",
        open_timeout: @request_timeout,
        read_timeout: @request_timeout
      ) { |connection| connection.request(request) }
    rescue IOError, SocketError, SystemCallError, Timeout::Error
      log_outcome(event: "resend_delivery_failed")
      raise Berufe::MailDelivery::ProviderUnavailable, "Resend is unavailable"
    end

    def handle_response(response)
      status = response.code.to_i
      return log_outcome(event: "resend_delivery_accepted", http_status: status) if status.between?(200, 299)

      log_outcome(event: "resend_delivery_failed", http_status: status)
      raise error_class(status), "Resend rejected the request"
    end

    def error_class(status)
      return Berufe::MailDelivery::ProviderUnavailable if [409, 429].include?(status)
      return Berufe::MailDelivery::ProviderUnavailable if status >= 500

      Berufe::MailDelivery::Rejected
    end

    def log_outcome(event:, http_status: nil)
      logger = @logger || (Rails.logger if defined?(Rails))
      return unless logger

      payload = {event:, provider: "resend"}
      payload[:http_status] = http_status if http_status
      request_id = Current.request_id if defined?(Current)
      payload[:request_id] = request_id unless request_id.to_s.empty?
      logger.info(payload)
    end
  end
end
