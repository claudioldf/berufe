# frozen_string_literal: true

require "rails_helper"

RSpec.describe ProfessionalRegistration do
  let(:account) do
    UserAccount.create!(
      phone_e164: "+5547999996001",
      role: "professional",
      status: "active",
      phone_verified_at: Time.current
    )
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

  it "claims an external profile in place, preserves its public snapshot during onboarding, and switches on submit" do
    service = create_external_service
    external_profile = ProfessionalProfile.create!(
      user_account: account,
      creation_source: "external",
      external_published_at: Time.current,
      profile_status: "published",
      display_name: "Ana Indicada",
      whatsapp_e164: account.phone_e164
    )
    external_revision = external_profile.working_revision
    external_revision.update!(
      profile_type: "external",
      status: "pending_review",
      submitted_at: Time.current
    )
    external_revision.professional_profile_services.create!(service:, is_primary: true)
    external_revision.professional_profile_service_areas.create!(city_code: "Joinville")
    external_profile.update!(
      working_revision: external_revision,
      published_revision: external_revision
    )
    now = Time.zone.parse("2026-08-20 16:00:00 UTC")

    claimed_profile = described_class.new.call(
      user_account: account,
      display_name: "Ana Souza",
      accepted: true,
      now:
    )

    self_service_revision = claimed_profile.working_revision
    expect(claimed_profile).to eq(external_profile)
    expect(account.reload).to have_attributes(
      registered_at: now,
      phone_verified_at: account.phone_verified_at
    )
    expect(claimed_profile.reload).to have_attributes(
      creation_source: "external",
      published_revision: external_revision,
      working_revision: self_service_revision
    )
    expect(self_service_revision).to have_attributes(
      profile_type: "self_service",
      status: "draft",
      display_name: "Ana Souza",
      whatsapp_e164: account.phone_e164
    )
    expect(self_service_revision.professional_profile_services.sole.service).to eq(service)
    expect(self_service_revision.professional_profile_service_areas.sole.neighborhood_code).to be_nil
    expect(PublicProfessionalProfileSerializer.new(claimed_profile).as_json).to include(
      profile_type: "external",
      claimed: true,
      display_name: "Ana Indicada"
    )

    photo = create_public_profile_photo(claimed_profile)
    claimed_profile.update!(birthdate: Date.new(1990, 4, 12), working_photo: photo)
    ProfessionalProfileSubmitter.new.call(profile: claimed_profile)

    expect(claimed_profile.reload).to have_attributes(
      creation_source: "external",
      profile_status: "published",
      published_revision: self_service_revision,
      published_photo: photo
    )
    expect(self_service_revision.reload.status).to eq("pending_review")
    expect(PublicProfessionalProfileSerializer.new(claimed_profile).as_json).to include(
      profile_type: "self_service",
      claimed: true,
      display_name: "Ana Souza"
    )
  end

  private

  def create_external_service
    category = ServiceCategory.create!(
      name: "Cadastro externo",
      slug: "cadastro-externo",
      icon: "i-lucide-wrench",
      is_active: true,
      sort_order: 0
    )
    Service.create!(
      category:,
      name: "Serviço indicado",
      slug: "servico-indicado",
      icon: "i-lucide-wrench",
      description: "Serviço herdado no cadastro.",
      aliases: [],
      is_active: true,
      sort_order: 0
    )
  end
end
