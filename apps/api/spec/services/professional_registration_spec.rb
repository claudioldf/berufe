# frozen_string_literal: true

require "rails_helper"

RSpec.describe ProfessionalRegistration do
  let(:account) do
    UserAccount.create!(phone_e164: "+5547999996001", role: "professional", status: "active")
  end

  it "records current legal versions and creates exactly one normalized draft profile atomically" do
    now = Time.zone.parse("2026-08-15 12:00:00 UTC")

    profile = described_class.new.call(
      user_account: account,
      display_name: "  Ana   Souza  ",
      accepted: true,
      now:
    )

    expect(profile).to be_persisted
    expect(profile.display_name).to eq("Ana Souza")
    expect(profile.profile_status).to eq("draft")
    expect(account.reload).to be_registration_completed
    expect(account.terms_accepted_at).to eq(now)
    expect(account.terms_version).to eq(LegalDocumentVersions::TERMS)
    expect(account.privacy_notice_version).to eq(LegalDocumentVersions::PRIVACY_NOTICE)
  end

  it "is retry-safe after completion and never creates or renames a second profile" do
    service = described_class.new
    original = service.call(user_account: account, display_name: "Ana Souza", accepted: true)
    accepted_at = account.reload.terms_accepted_at

    retried = service.call(user_account: account, display_name: "Nome Diferente", accepted: true)

    expect(retried).to eq(original)
    expect(account.reload.terms_accepted_at).to eq(accepted_at)
    expect(account.professional_profile.display_name).to eq("Ana Souza")
    expect(ProfessionalProfile.where(user_account: account).count).to eq(1)
  end

  it "returns field-specific validation without persisting partial acceptance" do
    expect do
      described_class.new.call(user_account: account, display_name: "A", accepted: false)
    end.to raise_error(described_class::Invalid) { |error|
      expect(error.field_errors).to eq(
        display_name: ["deve ter entre 3 e 70 caracteres"],
        accepted: ["deve ser confirmado"]
      )
    }

    expect(account.reload.terms_accepted_at).to be_nil
    expect(account.professional_profile).to be_nil
  end

  it "rejects admin and suspended accounts even when called outside the controller" do
    admin = UserAccount.create!(
      email: "admin@example.com",
      password: "a-secure-admin-password",
      password_confirmation: "a-secure-admin-password",
      role: "admin",
      status: "active"
    )
    suspended = UserAccount.create!(phone_e164: "+5547999996003", role: "professional", status: "suspended")

    [admin, suspended].each do |invalid_account|
      expect do
        described_class.new.call(user_account: invalid_account, display_name: "Ana Souza", accepted: true)
      end.to raise_error(described_class::Invalid)
    end
  end

  it "rolls the profile back if legal acceptance cannot be persisted" do
    allow(account).to receive(:update!).and_raise(ActiveRecord::RecordInvalid.new(account))

    expect do
      described_class.new.call(user_account: account, display_name: "Ana Souza", accepted: true)
    end.to raise_error(ActiveRecord::RecordInvalid)

    expect(ProfessionalProfile.where(user_account_id: account.id)).to be_empty
  end
end
