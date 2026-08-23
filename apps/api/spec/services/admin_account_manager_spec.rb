# frozen_string_literal: true

require "rails_helper"

RSpec.describe AdminAccountManager do
  let(:service) { described_class.new }

  it "provisions an administrator and records the operator atomically" do
    now = Time.zone.parse("2026-08-23 12:00:00 UTC")

    expect do
      account = service.provision!(
        email: "ADMIN@example.com",
        password: "a-secure-admin-password",
        password_confirmation: "a-secure-admin-password",
        operator_identifier: "ops@example.com",
        request_id: "production-provision",
        now:
      )

      expect(account).to have_attributes(email: "admin@example.com", role: "admin", status: "active")
    end.to change(UserAccount, :count).by(1).and change(AdminAccessEvent, :count).by(1)

    expect(AdminAccessEvent.last).to have_attributes(
      action: "provisioned",
      operator_identifier: "ops@example.com",
      request_id: "production-provision",
      created_at: now
    )
  end

  it "rolls back administrator provisioning when the audit event is invalid" do
    expect do
      service.provision!(
        email: "admin@example.com",
        password: "a-secure-admin-password",
        password_confirmation: "a-secure-admin-password",
        operator_identifier: "ops@example.com",
        request_id: "not a valid request id"
      )
    end.to raise_error(ArgumentError, "request_id is invalid")
      .and change(UserAccount, :count).by(0)
      .and change(AdminAccessEvent, :count).by(0)
  end

  it "resets the password, revokes every session, and records the action atomically" do
    now = Time.zone.parse("2026-08-15 12:00:00 UTC")
    account = provision_admin
    session, = ApplicationSession.issue!(user_account: account, now:)

    expect do
      service.reset_password!(
        email: "ADMIN@example.com",
        password: "a-different-secure-password",
        password_confirmation: "a-different-secure-password",
        operator_identifier: "ops@example.com",
        request_id: "manual-reset",
        now: now + 1.hour
      )
    end.to change(AdminAccessEvent, :count).by(1)

    expect(account.reload.authenticate("a-secure-admin-password")).to be(false)
    expect(account.authenticate("a-different-secure-password")).to eq(account)
    expect(session.reload.revoked_at).to eq(now + 1.hour)
    expect(AdminAccessEvent.find_by!(action: "password_reset").admin_user).to eq(account)
  end

  it "does not change the password or record an event when validation fails" do
    account = provision_admin
    event_count = AdminAccessEvent.count

    expect do
      service.reset_password!(
        email: "admin@example.com",
        password: "short",
        password_confirmation: "different",
        operator_identifier: "ops@example.com"
      )
    end.to raise_error(ActiveRecord::RecordInvalid)
      .and change(UserAccount, :count).by(0)
      .and change(AdminAccessEvent, :count).by(0)
    expect(account.reload.authenticate("a-secure-admin-password")).to eq(account)
    expect(AdminAccessEvent.count).to eq(event_count)
  end

  private

  def provision_admin
    UserAccount.create!(
      email: "admin@example.com",
      password: "a-secure-admin-password",
      password_confirmation: "a-secure-admin-password",
      role: "admin",
      status: "active"
    )
  end
end
