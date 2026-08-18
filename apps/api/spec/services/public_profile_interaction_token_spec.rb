# frozen_string_literal: true

require "rails_helper"

RSpec.describe PublicProfileInteractionToken do
  include ActiveSupport::Testing::TimeHelpers

  let(:issuer) { described_class.new }
  let(:attributes) do
    {
      interaction_id: SecureRandom.uuid,
      professional_id: SecureRandom.uuid,
      service_id: SecureRandom.uuid,
      search_event_id: SecureRandom.uuid
    }
  end

  it "round-trips only random profile and search context" do
    token = issuer.issue(**attributes)

    expect(issuer.verify(token)).to have_attributes(**attributes)
    expect(token).not_to include("Joinville", "Eletricista", "telefone")
  end

  it "allows nullable service/search context and rejects tampering, malformed payloads, and expiry" do
    now = Time.zone.parse("2026-08-17 18:30:00 UTC")
    token = travel_to(now) do
      issuer.issue(
        interaction_id: attributes[:interaction_id],
        professional_id: attributes[:professional_id],
        service_id: nil,
        search_event_id: nil
      )
    end

    travel_to(now) do
      expect(issuer.verify(token)).to have_attributes(service_id: nil, search_event_id: nil)
      expect(issuer.verify("#{token}changed")).to be_nil
    end
    travel_to(now + described_class::TTL + 1.second) do
      expect(issuer.verify(token)).to be_nil
    end

    malformed = Rails.application.message_verifier(described_class::PURPOSE).generate(
      {"interaction_id" => "not-a-uuid"},
      purpose: described_class::PURPOSE
    )
    expect(issuer.verify(malformed)).to be_nil
  ensure
    travel_back
  end
end
