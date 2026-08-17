# frozen_string_literal: true

require "rails_helper"

RSpec.describe CurrentSessionSerializer do
  it "returns the approved session summary without phone, token digests, or timestamps unrelated to access" do
    now = Time.zone.parse("2026-08-15 12:00:00 UTC")
    account = UserAccount.create!(phone_e164: "+5547999994001", role: "professional", status: "active")
    application_session = ApplicationSession.issue!(user_account: account, now:).first

    serialized = described_class.new(application_session:).as_json

    expect(serialized).to eq(
      account: {
        id: account.id,
        role: "professional",
        status: "active",
        registration_completed: false
      },
      session: {
        authentication_method: "sms_otp",
        authenticated_at: now,
        idle_expires_at: now + 7.days,
        absolute_expires_at: now + 30.days
      }
    )
    expect(serialized.to_json).not_to include(
      account.phone_e164,
      application_session.token_digest,
      "last_active_at",
      "created_at",
      "updated_at"
    )
  end
end
