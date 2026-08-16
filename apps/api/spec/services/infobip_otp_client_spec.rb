# frozen_string_literal: true

require_relative "../../app/services/sms_otp"
require_relative "../../app/services/infobip_otp_client"

module InfobipOtpClientSpecSupport
  Response = Struct.new(:code, :body, :headers) do
    def [](name)
      headers[name]
    end
  end

  class FakeConnection
    attr_reader :last_request

    def initialize(response)
      @response = response
    end

    def request(request)
      @last_request = request
      @response
    end
  end

  class FakeHttp
    attr_reader :connection, :options

    def initialize(response)
      @connection = FakeConnection.new(response)
    end

    def start(_host, _port, **options)
      @options = options
      yield connection
    end
  end
end

RSpec.describe InfobipOtpClient do
  def build_client(response, allowed_phone_numbers: nil, logger: nil)
    http = InfobipOtpClientSpecSupport::FakeHttp.new(response)
    client = described_class.new(
      base_url: "https://example.api.infobip.com",
      api_key: "private-api-key",
      application_id: "application-id",
      message_id: "message-id",
      sender: "Berufe",
      allowed_phone_numbers:,
      logger:,
      http:
    )
    [client, http]
  end

  it "starts a challenge with the purpose-specific 2FA endpoint" do
    client, http = build_client(InfobipOtpClientSpecSupport::Response.new("200", '{"pinId":"pin-reference"}', {}))

    challenge = client.start_challenge(phone: "+5547999999999")
    request_body = JSON.parse(http.connection.last_request.body)

    expect(challenge.reference).to eq("pin-reference")
    expect(http.connection.last_request.path).to eq("/2fa/2/pin")
    expect(http.connection.last_request["Authorization"]).to eq("App private-api-key")
    expect(request_body).to include(
      "applicationId" => "application-id",
      "messageId" => "message-id",
      "from" => "Berufe",
      "to" => "+5547999999999"
    )
  end

  it "allows only configured recipients when a non-production allowlist is present" do
    response = InfobipOtpClientSpecSupport::Response.new("200", '{"pinId":"pin-reference"}', {})
    client, http = build_client(response, allowed_phone_numbers: ["+5547999999999"])

    expect(client.start_challenge(phone: "+5547999999999").status).to eq("accepted")

    expect { client.start_challenge(phone: "+5547888888888") }
      .to raise_error(SmsOtp::DeliveryRejected, "SMS OTP recipient is not allowed in this environment")
    expect(JSON.parse(http.connection.last_request.body).fetch("to")).to eq("+5547999999999")
  end

  it "logs a provider outcome without phone numbers or provider references" do
    logger = spy("logger")
    client, = build_client(
      InfobipOtpClientSpecSupport::Response.new("200", '{"pinId":"private-reference"}', {}),
      logger:
    )

    client.start_challenge(phone: "+5547999999999")

    expect(logger).to have_received(:info) do |payload|
      expect(payload).to include(
        event: "infobip_otp_request_accepted",
        provider: "infobip",
        operation: "start_challenge",
        http_status: 200
      )
      expect(payload.to_json).not_to include("+5547999999999", "private-reference")
    end
  end

  it "verifies the provider challenge without exposing a provider session" do
    client, http = build_client(InfobipOtpClientSpecSupport::Response.new("200", '{"verified":true}', {}))

    verification = client.verify_challenge(reference: "pin-reference", code: "123456")

    expect(verification.verified).to be(true)
    expect(http.connection.last_request.path).to eq("/2fa/2/pin/pin-reference/verify")
  end

  it "preserves retry timing without returning the provider response body" do
    client, = build_client(
      InfobipOtpClientSpecSupport::Response.new("429", '{"requestError":"private"}', {"Retry-After" => "30"})
    )

    expect { client.start_challenge(phone: "+5547999999999") }
      .to raise_error(SmsOtp::RateLimited) { |error|
        expect(error.retry_after).to eq("30")
        expect(error.message).not_to include("private")
      }
  end

  it "maps provider authentication and authorization failures to unavailability" do
    ["401", "403"].each do |status|
      client, = build_client(
        InfobipOtpClientSpecSupport::Response.new(status, '{"requestError":"private"}', {})
      )

      expect { client.start_challenge(phone: "+5547999999999") }
        .to raise_error(SmsOtp::ProviderUnavailable, "SMS OTP provider rejected the request")
    end
  end

  it "maps malformed provider responses to a safe unavailable error" do
    client, = build_client(InfobipOtpClientSpecSupport::Response.new("200", "not-json", {}))

    expect { client.start_challenge(phone: "+5547999999999") }
      .to raise_error(SmsOtp::ProviderUnavailable, "SMS OTP provider returned an invalid response")
  end

  it "maps provider timeouts to a safe unavailable error" do
    timeout_http = Class.new do
      def self.start(*, **)
        raise Timeout::Error
      end
    end
    client = described_class.new(
      base_url: "https://example.api.infobip.com",
      api_key: "private-api-key",
      application_id: "application-id",
      message_id: "message-id",
      sender: "Berufe",
      http: timeout_http
    )

    expect { client.start_challenge(phone: "+5547999999999") }
      .to raise_error(SmsOtp::ProviderUnavailable, "SMS OTP provider is unavailable")
  end
end
