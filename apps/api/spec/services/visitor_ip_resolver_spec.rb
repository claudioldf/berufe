# frozen_string_literal: true

require "rails_helper"

RSpec.describe VisitorIpResolver do
  it "uses Railway's canonical visitor IP when the application peer is private" do
    request = instance_double(ActionDispatch::Request, headers: {"X-Real-IP" => "2001:4860:4860::8888"}, remote_ip: "10.0.0.2")

    expect(described_class.new.call(request)).to eq("2001:4860:4860::8888")
  end

  it "prefers a public request peer and ignores an untrusted malformed override" do
    fallback_request = instance_double(ActionDispatch::Request, headers: {}, remote_ip: "8.8.4.4")
    malformed_request = instance_double(ActionDispatch::Request, headers: {"X-Real-IP" => "not-an-ip"}, remote_ip: "8.8.4.4")
    spoofed_request = instance_double(ActionDispatch::Request, headers: {"X-Real-IP" => "1.1.1.1"}, remote_ip: "8.8.4.4")

    expect(described_class.new.call(fallback_request)).to eq("8.8.4.4")
    expect(described_class.new.call(malformed_request)).to eq("8.8.4.4")
    expect(described_class.new.call(spoofed_request)).to eq("8.8.4.4")
  end
end
