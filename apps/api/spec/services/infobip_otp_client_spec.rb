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
  def build_client(response)
    http = InfobipOtpClientSpecSupport::FakeHttp.new(response)
    client = described_class.new(
      base_url: "https://example.api.infobip.com",
      api_key: "private-api-key",
      application_id: "application-id",
      message_id: "message-id",
      sender: "Berufe",
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
    expect(request_body).to include("applicationId" => "application-id", "messageId" => "message-id", "from" => "Berufe")
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

  it "maps malformed provider responses to a safe unavailable error" do
    client, = build_client(InfobipOtpClientSpecSupport::Response.new("200", "not-json", {}))

    expect { client.start_challenge(phone: "+5547999999999") }
      .to raise_error(SmsOtp::ProviderUnavailable, "SMS OTP provider returned an invalid response")
  end
end
