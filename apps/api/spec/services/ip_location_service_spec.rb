# frozen_string_literal: true

require "rails_helper"

RSpec.describe IpLocationService do
  let(:client) { instance_double(IpdataClient) }
  let(:cache) { ActiveSupport::Cache::MemoryStore.new }
  let(:record) { IpdataClient::Result.new(city: "Joinville", state_code: "SC", country_code: "BR") }

  it "returns a complete coarse location and caches it without retaining the raw IP in the key" do
    allow(client).to receive(:lookup).with("8.8.8.8").and_return(record)
    allow(cache).to receive(:write).and_call_original
    service = described_class.new(client:, cache:)

    first = service.call("8.8.8.8")
    second = service.call("8.8.8.8")

    expect(first).to eq(described_class::Location.new(city: "Joinville", state_code: "SC", country_code: "BR"))
    expect(second).to eq(first)
    expect(client).to have_received(:lookup).once
    expect(cache).to have_received(:write) do |key, _value, **_options|
      expect(key).to start_with("ip-location:")
      expect(key).not_to include("8.8.8.8")
    end
  end

  it "rejects malformed, private, reserved, and documentation addresses without calling ipdata" do
    allow(client).to receive(:lookup)
    service = described_class.new(client:, cache:)

    expect(service.call("not-an-ip")).to be_nil
    expect(service.call("127.0.0.1")).to be_nil
    expect(service.call("10.0.0.1")).to be_nil
    expect(service.call("203.0.113.8")).to be_nil
    expect(service.call("::1")).to be_nil
    expect(client).not_to have_received(:lookup)
  end

  it "negative-caches incomplete responses and logs only the provider error class" do
    allow(client).to receive(:lookup).and_raise(IpdataClient::LookupError, "private provider detail for 8.8.8.8")
    allow(Rails.logger).to receive(:warn)
    service = described_class.new(client:, cache:)

    expect(service.call("8.8.8.8")).to be_nil
    expect(service.call("8.8.8.8")).to be_nil

    expect(client).to have_received(:lookup).once
    expect(Rails.logger).to have_received(:warn).with(
      "ipdata_lookup_failed class=IpdataClient::LookupError request_id=#{Current.request_id}"
    ).once
  end
end
