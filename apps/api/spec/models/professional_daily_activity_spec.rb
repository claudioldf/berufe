# frozen_string_literal: true

require "rails_helper"

RSpec.describe ProfessionalDailyActivity do
  let(:account) do
    UserAccount.create!(phone_e164: "+5547999981001", role: "professional", status: "active")
  end
  let(:profile) do
    ProfessionalProfile.create!(user_account: account, display_name: "Atividade Profissional")
  end

  it "atomically increments only the requested counter on the São Paulo product date" do
    occurred_at = Time.zone.parse("2026-08-18 02:30:00 UTC")

    described_class.increment!(professional_id: profile.id, counter: :profile_updates, occurred_at:)
    described_class.increment!(professional_id: profile.id, counter: :profile_updates, occurred_at:)
    described_class.increment!(professional_id: profile.id, counter: :evidence_creations, occurred_at:)

    expect(described_class.sole).to have_attributes(
      professional: profile,
      activity_date: Date.new(2026, 8, 17),
      profile_updates: 2,
      evidence_creations: 1,
      relationship_interactions: 0,
      quotes_created: 0
    )
  end

  it "rejects unknown counters and enforces non-negative values in Rails and PostgreSQL" do
    activity = described_class.create!(professional: profile, activity_date: Date.new(2026, 8, 18))

    expect do
      described_class.increment!(professional_id: profile.id, counter: :logins)
    end.to raise_error(KeyError)

    activity.profile_updates = -1
    expect(activity).not_to be_valid
    expect(activity.errors).to have_key(:profile_updates)
    expect do
      activity.update_columns(profile_updates: -1)
    end.to raise_error(ActiveRecord::StatementInvalid)
  end
end
