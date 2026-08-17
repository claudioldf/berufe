# frozen_string_literal: true

require "rails_helper"

RSpec.describe PublicProfessionalProfileSerializer do
  let(:account) do
    UserAccount.create!(phone_e164: "+5547999996601", role: "professional", status: "active")
  end
  let(:profile) do
    ProfessionalProfile.create!(
      user_account: account,
      display_name: "Ana Souza",
      headline: "Elétrica residencial.",
      bio: "Instalações em Joinville.",
      whatsapp_e164: account.phone_e164
    )
  end

  it "returns nothing for a draft without an approved public pointer" do
    expect(described_class.new(profile).as_json).to be_nil
  end

  it "keeps the approved snapshot public while a material edit is pending" do
    approved = profile.working_revision
    category = ServiceCategory.create!(
      name: "Instalações Revision",
      slug: "instalacoes-revision",
      icon: "i-lucide-wrench",
      is_active: true,
      sort_order: 0
    )
    service = Service.create!(
      category:,
      name: "Eletricista Revision",
      slug: "eletricista-revision",
      icon: "i-lucide-zap",
      description: "Instalações elétricas.",
      aliases: ["elétrica"],
      is_active: true,
      sort_order: 0
    )
    approved.professional_profile_services.create!(service:, is_primary: true, note: "Quadros")
    approved.professional_profile_service_areas.create!(city_code: "Joinville")
    approved.update!(status: "approved", reviewed_at: Time.current)
    profile.update!(profile_status: "published", published_revision: approved)

    before_edit = described_class.new(profile.reload).as_json
    ProfessionalProfileIdentityUpdater.new.call(
      profile:,
      attributes: {
        display_name: "Ana Obras",
        headline: "Nova apresentação pendente.",
        bio: "Conteúdo ainda não aprovado.",
        whatsapp: account.phone_e164,
        instagram: nil,
        youtube: nil
      }
    )

    profile.reload
    expect(profile.working_revision).not_to eq(approved)
    expect(profile.working_revision.status).to eq("pending_review")
    expect(profile.published_revision).to eq(approved)
    expect(profile.working_revision.professional_profile_services.sole.service).to eq(service)
    expect(profile.working_revision.professional_profile_service_areas.sole.neighborhood_code).to be_nil
    expect(described_class.new(profile).as_json).to eq(before_edit)
    expect(before_edit).to include(
      public_slug: "ana-souza",
      display_name: "Ana Souza",
      headline: "Elétrica residencial."
    )
  end

  it "excludes a suspended account even when an approved pointer exists" do
    approved = profile.working_revision
    approved.update!(status: "approved")
    profile.update!(profile_status: "published", published_revision: approved)
    account.update!(status: "suspended")

    expect(described_class.new(profile.reload).as_json).to be_nil
  end
end
