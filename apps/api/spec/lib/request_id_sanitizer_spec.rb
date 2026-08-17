# frozen_string_literal: true

require_relative "../../lib/request_id_sanitizer"

RSpec.describe RequestIdSanitizer do
  let(:application) { ->(environment) { [200, {}, [environment[described_class::HEADER].to_s]] } }
  let(:middleware) { described_class.new(application) }

  it "keeps a bounded ASCII request ID" do
    _, _, body = middleware.call(described_class::HEADER => "web_request-123.abc")

    expect(body).to eq(["web_request-123.abc"])
  end

  it "drops an unsafe request ID before Rails logging and correlation" do
    _, _, body = middleware.call(described_class::HEADER => "phone=+5547999999999\nsecret")

    expect(body).to eq([""])
  end
end
