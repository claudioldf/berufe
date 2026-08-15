# frozen_string_literal: true

require "rails_helper"

RSpec.describe UserAccount, type: :model do
  it "uses a Rails UUID and a unique verified phone as the stable identity" do
    account = described_class.create!(
      phone_e164: "+5547999991111",
      role: "professional",
      status: "active"
    )

    expect(account.id).to match(/\A[0-9a-f-]{36}\z/)
    expect(account).not_to be_admin
    expect do
      described_class.create!(phone_e164: account.phone_e164, role: "professional", status: "active")
    end.to raise_error(ActiveRecord::RecordInvalid)
  end

  it "recognizes deliberately provisioned admin accounts" do
    account = described_class.new(
      phone_e164: "+5547999992222",
      role: "admin",
      status: "active"
    )

    expect(account).to be_admin
  end

  it "revokes all sessions immediately when access is suspended" do
    now = Time.zone.parse("2026-08-15 12:00:00 UTC")
    account = described_class.create!(
      phone_e164: "+5547999991111",
      role: "professional",
      status: "active"
    )
    first_session, = ApplicationSession.issue!(user_account: account, now:)
    second_session, = ApplicationSession.issue!(user_account: account, now: now + 1.minute)

    expect(account).to be_active
    account.suspend!(now: now + 2.minutes)

    expect(account.reload.status).to eq("suspended")
    expect(account).not_to be_active
    expect(first_session.reload.revoked_at).to eq(now + 2.minutes)
    expect(second_session.reload.revoked_at).to eq(now + 2.minutes)
  end

  it "supports an administrative revoke-all action without suspending the account" do
    now = Time.zone.parse("2026-08-15 12:00:00 UTC")
    account = described_class.create!(
      phone_e164: "+5547999991111",
      role: "professional",
      status: "active"
    )
    session, = ApplicationSession.issue!(user_account: account, now:)

    expect(account.revoke_all_sessions!(now: now + 1.minute)).to eq(1)
    expect(account.reload).to be_active
    expect(session.reload.revoked_at).to eq(now + 1.minute)
  end
end
