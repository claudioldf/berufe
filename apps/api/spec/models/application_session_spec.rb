# frozen_string_literal: true

require "rails_helper"

RSpec.describe ApplicationSession, type: :model do
  include ActiveSupport::Testing::TimeHelpers

  after { travel_back }

  it "hashes professional session material and applies the documented boundaries" do
    now = Time.zone.parse("2026-08-15 12:00:00 UTC")
    account = create_account(role: "professional")
    session, token = described_class.issue!(user_account: account, now:)

    expect(token).to match(/\A[A-Za-z0-9_-]{43}\z/)
    expect(session.token_digest).to eq(described_class.digest_token(token))
    expect(session.token_digest).not_to eq(token)
    expect(session.authentication_method).to eq("sms_otp")
    expect(session.idle_expires_at).to eq(now + 7.days)
    expect(session.absolute_expires_at).to eq(now + 30.days)
    expect(session).to be_active(now: session.idle_expires_at - 1.second)
    expect(session).not_to be_active(now: session.idle_expires_at)
  end

  it "uses password authentication and the shorter administrator expiry boundaries" do
    now = Time.zone.parse("2026-08-15 12:00:00 UTC")
    account = create_account(role: "admin")
    session, = described_class.issue!(user_account: account, now:)

    expect(session.authentication_method).to eq("password")
    expect(session.idle_expires_at).to eq(now + 30.minutes)
    expect(session.absolute_expires_at).to eq(now + 12.hours)
    expect(session).to be_active(now: session.idle_expires_at - 1.second)
    expect(session).not_to be_active(now: session.idle_expires_at)
  end

  it "throttles last-activity writes and never extends beyond the absolute expiry" do
    now = Time.zone.parse("2026-08-15 12:00:00 UTC")
    account = create_account(role: "professional")
    session, = described_class.issue!(user_account: account, now:)

    expect(session.record_activity!(now: now + 299.seconds)).to be(false)
    expect(session.reload.last_active_at).to eq(now)
    expect(session.record_activity!(now: now + 300.seconds)).to be(true)
    expect(session.reload.last_active_at).to eq(now + 300.seconds)

    session.update!(
      last_active_at: session.absolute_expires_at - 6.days,
      idle_expires_at: session.absolute_expires_at - 1.second
    )
    activity_time = session.absolute_expires_at - 5.days
    expect(session.record_activity!(now: activity_time)).to be(true)
    expect(session.reload.idle_expires_at).to eq(session.absolute_expires_at)
    expect(session.record_activity!(now: session.absolute_expires_at)).to be(false)
  end

  it "treats revoked sessions as inactive" do
    now = Time.zone.parse("2026-08-15 12:00:00 UTC")
    account = create_account(role: "professional")
    session, = described_class.issue!(user_account: account, now:)
    session.update!(revoked_at: now + 1.minute)

    expect(session).not_to be_active(now: now + 2.minutes)
  end

  it "revokes a session exactly once" do
    now = Time.zone.parse("2026-08-15 12:00:00 UTC")
    account = create_account(role: "professional")
    session, = described_class.issue!(user_account: account, now:)

    expect(session.revoke!(now: now + 1.minute)).to be(true)
    expect(session.revoke!(now: now + 2.minutes)).to be(false)
    expect(session.reload.revoked_at).to eq(now + 1.minute)
  end

  private

  def create_account(role:)
    if role == "admin"
      UserAccount.create!(
        email: "admin@example.com",
        password: "a-secure-admin-password",
        password_confirmation: "a-secure-admin-password",
        role:,
        status: "active"
      )
    else
      UserAccount.create!(phone_e164: "+5547999991111", role:, status: "active")
    end
  end
end
