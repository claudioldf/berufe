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
    expect(account).to be_professional
    expect(account).not_to be_phone_verified
    expect(account).not_to be_registered
    expect(account).not_to be_registration_completed
    expect do
      described_class.create!(phone_e164: account.phone_e164, role: "professional", status: "active")
    end.to raise_error(ActiveRecord::RecordInvalid)
  end

  it "tracks OTP verification and registration separately and prevents registration before verification" do
    account = described_class.create!(
      phone_e164: "+5547999994444",
      role: "professional",
      status: "active"
    )
    account.registered_at = Time.current

    expect(account).not_to be_valid
    expect(account.errors[:registered_at]).to be_present

    account.phone_verified_at = 1.minute.ago
    account.terms_accepted_at = Time.current
    account.terms_version = LegalDocumentVersions::TERMS
    account.privacy_notice_version = LegalDocumentVersions::PRIVACY_NOTICE
    expect(account).to be_valid
    expect(account).to be_phone_verified
    expect(account).to be_registered
  end

  it "requires the acceptance timestamp and both legal document versions as one complete record" do
    account = described_class.new(
      phone_e164: "+5547999993333",
      role: "professional",
      status: "active",
      terms_accepted_at: Time.current,
      terms_version: "0.2"
    )

    expect(account).not_to be_valid
    expect(account.errors[:terms_accepted_at]).to be_present

    account.privacy_notice_version = "0.2"
    expect(account).to be_valid
  end

  it "requires the current legal versions before treating registration as complete" do
    account = described_class.create!(
      phone_e164: "+5547999993344",
      role: "professional",
      status: "active",
      phone_verified_at: 2.minutes.ago,
      registered_at: 1.minute.ago,
      terms_accepted_at: 1.minute.ago,
      terms_version: "0.3",
      privacy_notice_version: "0.3"
    )
    ProfessionalProfile.create!(user_account: account, display_name: "Ana Souza")

    expect(account.reload).not_to be_registration_completed

    account.update!(
      terms_version: LegalDocumentVersions::TERMS,
      privacy_notice_version: LegalDocumentVersions::PRIVACY_NOTICE
    )
    expect(account.reload).to be_registration_completed
  end

  it "keeps every delegated-account-management eligibility check agreeing with #impersonatable?" do
    account = described_class.create!(
      phone_e164: "+5547999993355",
      role: "professional",
      status: "active",
      phone_verified_at: 2.minutes.ago,
      registered_at: 1.minute.ago,
      terms_accepted_at: 1.minute.ago,
      terms_version: "0.3",
      privacy_notice_version: LegalDocumentVersions::PRIVACY_NOTICE
    )
    ProfessionalProfile.create!(user_account: account, display_name: "Ana Souza")
    account.reload
    admin = described_class.create!(
      email: "impersonation-eligibility-admin@example.com",
      password: "a-secure-admin-password",
      password_confirmation: "a-secure-admin-password",
      role: "admin",
      status: "active"
    )
    admin_session = ApplicationSession.issue!(user_account: admin).first

    expect(account).not_to be_impersonatable
    expect(ApplicationSession.new(impersonated_user_account: account)).not_to be_impersonation_target_eligible
    account.reload # building the throwaway session above caches an inverse association on account
    expect do
      Admin::ProfessionalImpersonation.new.start!(application_session: admin_session, professional_account_id: account.id)
    end.to raise_error(Admin::ProfessionalImpersonation::Unavailable)

    account.update!(terms_version: LegalDocumentVersions::TERMS)
    account.reload

    expect(account).to be_impersonatable
    expect(ApplicationSession.new(impersonated_user_account: account)).to be_impersonation_target_eligible
    expect do
      Admin::ProfessionalImpersonation.new.start!(application_session: admin_session, professional_account_id: account.id)
    end.not_to raise_error
  end

  it "keeps administrator credentials separate from professional phone credentials" do
    account = described_class.create!(
      email: " ADMIN@EXAMPLE.COM ",
      password: "a-secure-admin-password",
      password_confirmation: "a-secure-admin-password",
      role: "admin",
      status: "active"
    )

    expect(account).to be_admin
    expect(account.email).to eq("admin@example.com")
    expect(account.phone_e164).to be_nil
    expect(account.password_digest).not_to eq("a-secure-admin-password")
    expect(account.authenticate("a-secure-admin-password")).to eq(account)

    account.phone_e164 = "+5547999992222"
    expect(account).not_to be_valid
  end

  it "rejects short and overlong administrator passwords" do
    account = described_class.new(email: "admin@example.com", role: "admin", status: "active")

    account.password = account.password_confirmation = "short"
    expect(account).not_to be_valid
    expect(account.errors[:password]).to be_present

    account.password = account.password_confirmation = "á" * 37
    expect(account).not_to be_valid
    expect(account.errors[:password]).to be_present
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
