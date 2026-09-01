# frozen_string_literal: true

require_relative "../../../lib/berufe/mail_delivery"
require_relative "../../../lib/berufe/resend_mail_client"

module ResendMailClientSpecSupport
  Response = Struct.new(:code, :body, :headers)

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
    attr_reader :connection, :options, :host, :port

    def initialize(response)
      @connection = FakeConnection.new(response)
    end

    def start(host, port, **options)
      @host = host
      @port = port
      @options = options
      yield connection
    end
  end

  # Stands in for the Mail::Message ActionMailer's delivery method receives —
  # only the surface ResendMailClient reads from it.
  FakeMail = Struct.new(:from_field, :to, :subject, :html_part, :text_part, :body, :mime_type, :message_id) do
    def [](name)
      (name == :from) ? from_field : nil
    end
  end

  FakeFromField = Struct.new(:formatted)
  FakePart = Struct.new(:decoded)
end

RSpec.describe Berufe::ResendMailClient do
  def build_client(response, request_timeout: 5, logger: nil)
    http = ResendMailClientSpecSupport::FakeHttp.new(response)
    client = described_class.new(
      api_key: "resend-secret",
      base_url: "https://api.resend.com",
      request_timeout:,
      logger:,
      http:
    )
    [client, http]
  end

  def build_mail(
    to: ["marina@example.com"],
    subject: "Como foi o serviço?",
    html: "<p>Olá</p>",
    text: "Olá",
    message_id: "customer-recommendation-1@berufe.com.br"
  )
    ResendMailClientSpecSupport::FakeMail.new(
      ResendMailClientSpecSupport::FakeFromField.new(["Berufe <nao-responda@berufe.com.br>"]),
      to,
      subject,
      html && ResendMailClientSpecSupport::FakePart.new(html),
      text && ResendMailClientSpecSupport::FakePart.new(text),
      nil,
      "multipart/alternative",
      message_id
    )
  end

  it "posts the message to Resend's HTTP API with the bearer key and idempotency key" do
    client, http = build_client(ResendMailClientSpecSupport::Response.new("200", '{"id":"provider-id"}', {}))
    mail = build_mail

    client.deliver!(mail)

    request = http.connection.last_request
    expect(request.path).to eq("/emails")
    expect(request["Authorization"]).to eq("Bearer resend-secret")
    expect(request["Content-Type"]).to eq("application/json")
    expect(request["Idempotency-Key"]).to eq("customer-recommendation-1@berufe.com.br")
    expect(JSON.parse(request.body)).to eq(
      "from" => "Berufe <nao-responda@berufe.com.br>",
      "to" => ["marina@example.com"],
      "subject" => "Como foi o serviço?",
      "html" => "<p>Olá</p>",
      "text" => "Olá"
    )
  end

  it "opens the connection with an explicit open and read timeout" do
    client, http = build_client(ResendMailClientSpecSupport::Response.new("200", '{"id":"provider-id"}', {}), request_timeout: 3)

    client.deliver!(build_mail)

    expect(http.host).to eq("api.resend.com")
    expect(http.port).to eq(443)
    expect(http.options).to include(use_ssl: true, open_timeout: 3.0, read_timeout: 3.0)
  end

  it "returns the mail object on success" do
    client, = build_client(ResendMailClientSpecSupport::Response.new("200", '{"id":"provider-id"}', {}))
    mail = build_mail

    expect(client.deliver!(mail)).to be(mail)
  end

  it "treats rate limiting, resource conflicts, and server errors as retryable" do
    ["409", "429", "500", "503"].each do |status|
      client, = build_client(ResendMailClientSpecSupport::Response.new(status, "{}", {}))

      expect { client.deliver!(build_mail) }
        .to raise_error(Berufe::MailDelivery::ProviderUnavailable)
    end
  end

  it "treats validation and authentication failures as permanent" do
    ["400", "401", "403", "404", "422"].each do |status|
      client, = build_client(ResendMailClientSpecSupport::Response.new(status, "{}", {}))

      expect { client.deliver!(build_mail) }
        .to raise_error(Berufe::MailDelivery::Rejected)
    end
  end

  it "maps network failures to a provider-unavailable error" do
    timeout_http = Class.new do
      def self.start(*, **)
        raise Timeout::Error
      end
    end
    client = described_class.new(api_key: "resend-secret", http: timeout_http)

    expect { client.deliver!(build_mail) }.to raise_error(Berufe::MailDelivery::ProviderUnavailable)
  end

  it "logs a provider outcome without recipient or body details" do
    logger = spy("logger")
    client, = build_client(ResendMailClientSpecSupport::Response.new("200", '{"id":"provider-id"}', {}), logger:)

    client.deliver!(build_mail)

    expect(logger).to have_received(:info) do |payload|
      expect(payload).to include(event: "resend_delivery_accepted", provider: "resend", http_status: 200)
      expect(payload.to_json).not_to include("marina@example.com", "Olá")
    end
  end

  it "falls back to a single-part body when the message has no html or text part" do
    client, http = build_client(ResendMailClientSpecSupport::Response.new("200", '{"id":"provider-id"}', {}))
    mail = build_mail(html: nil, text: nil)
    mail.body = ResendMailClientSpecSupport::FakePart.new("plain body")
    mail.mime_type = "text/plain"

    client.deliver!(mail)

    expect(JSON.parse(http.connection.last_request.body)).to include("text" => "plain body")
  end
end
