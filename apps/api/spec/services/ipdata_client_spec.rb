# frozen_string_literal: true

require "rails_helper"

RSpec.describe IpdataClient do
  let(:body) { {city: "Joinville", region_code: "sc", country_code: "br"}.to_json }
  let(:response) { instance_double(Net::HTTPOK, body:) }
  let(:connection) { instance_double(Net::HTTP) }
  let(:http) { class_double(Net::HTTP) }
  let(:requested) { [] }

  before do
    allow(response).to receive(:is_a?).and_return(false)
    allow(response).to receive(:is_a?).with(Net::HTTPSuccess).and_return(true)
    allow(connection).to receive(:request) { |request| requested << request and response }
    allow(http).to receive(:start) { |*_args, **_options, &block| block.call(connection) }
  end

  it "requests only the needed fields with the API key and normalizes the result" do
    result = described_class.new(api_key: "secret", http:).lookup("189.46.118.153")

    expect(result).to eq(described_class::Result.new(city: "Joinville", state_code: "SC", country_code: "BR"))
    expect(http).to have_received(:start).with("api.ipdata.co", 443, hash_including(use_ssl: true, open_timeout: 2))
    expect(requested.first.path).to eq("/189.46.118.153?api-key=secret&fields=city%2Cregion_code%2Ccountry_code")
  end

  it "returns nil when a field is missing" do
    allow(response).to receive(:body).and_return({city: "Joinville", region_code: nil, country_code: "BR"}.to_json)

    expect(described_class.new(api_key: "secret", http:).lookup("189.46.118.153")).to be_nil
  end

  it "raises a LookupError without the response body for non-success responses" do
    allow(response).to receive(:is_a?).with(Net::HTTPSuccess).and_return(false)
    allow(response).to receive(:code).and_return("403")

    expect { described_class.new(api_key: "secret", http:).lookup("189.46.118.153") }
      .to raise_error(described_class::LookupError, "ipdata responded with HTTP 403")
  end

  it "wraps network failures and malformed JSON" do
    allow(http).to receive(:start).and_raise(Errno::ECONNREFUSED)
    expect { described_class.new(api_key: "secret", http:).lookup("189.46.118.153") }
      .to raise_error(described_class::LookupError)

    allow(http).to receive(:start) { |*_args, **_options, &block| block.call(connection) }
    allow(response).to receive(:body).and_return("<html>")
    expect { described_class.new(api_key: "secret", http:).lookup("189.46.118.153") }
      .to raise_error(described_class::LookupError)
  end
end
