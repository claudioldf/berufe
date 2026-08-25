# frozen_string_literal: true

require "rails_helper"

RSpec.describe PublicInteractionToken do
  include ActiveSupport::Testing::TimeHelpers

  let(:service_id) { SecureRandom.uuid }
  let(:event_id) { SecureRandom.uuid }
  let(:issuer) { described_class.new }

  it "round-trips only random search and optional service context" do
    token = issuer.issue(search_event_id: event_id, service_id:)

    expect(issuer.verify(token)).to have_attributes(
      search_event_id: event_id,
      service_id:,
      service_ids: [service_id]
    )
    expect(token).not_to include("Joinville", "encanador", "query")
  end

  it "rejects tampering and expiry" do
    now = Time.zone.parse("2026-08-17 18:30:00 UTC")
    token = travel_to(now) { issuer.issue(search_event_id: event_id, service_id:) }

    expect(issuer.verify("#{token}changed")).to be_nil
    travel_to(now + described_class::TTL + 1.second) do
      expect(issuer.verify(token)).to be_nil
    end
  end

  it "rejects a token generated for another purpose" do
    token = Rails.application.message_verifier("other-public-purpose").generate(
      {"search_event_id" => event_id},
      purpose: "other-public-purpose"
    )

    expect(issuer.verify(token)).to be_nil
  end
end
