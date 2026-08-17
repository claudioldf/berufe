# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Professional profile moderation" do
  let(:admin) do
    UserAccount.create!(
      email: "profile-moderation@example.com",
      password: "a-secure-admin-password",
      password_confirmation: "a-secure-admin-password",
      role: "admin",
      status: "active"
    )
  end
  let(:account) { UserAccount.create!(phone_e164: "+5547999998206", role: "professional", status: "active") }
  let(:profile) do
    ProfessionalProfile.create!(
      user_account: account,
      display_name: "Ana Souza",
      headline: "Elétrica residencial.",
      bio: "Instalações em Joinville.",
      whatsapp_e164: account.phone_e164
    )
  end
  let(:context) { AdminActionContext.new(admin_user_id: admin.id, request_id: "profile-moderation") }

  it "publishes the first approved revision and its exact relational snapshot" do
    revision = profile.working_revision
    service = select_service(revision, slug: "eletricista-primeira-revisao")
    revision.professional_profile_service_areas.create!(city_code: "Joinville")
    revision.update!(status: "pending_review", submitted_at: Time.current)

    decide(revision, "approved")

    expect(profile.reload).to have_attributes(
      profile_status: "published",
      published_revision: revision,
      working_revision: revision
    )
    expect(PublicProfessionalProfileSerializer.new(profile).as_json).to include(
      displayName: "Ana Souza",
      services: [{id: service.id, name: service.name, slug: service.slug, isPrimary: true, note: nil}],
      coverage: {allJoinville: true, neighborhoods: []}
    )
  end

  it "atomically swaps an edited snapshot and supersedes the former revision" do
    original = publish_initial_revision
    original_public = PublicProfessionalProfileSerializer.new(profile.reload).as_json

    ProfessionalProfileIdentityUpdater.new.call(
      profile:,
      attributes: {
        display_name: "Ana Obras",
        headline: "Projetos elétricos residenciais.",
        bio: "Novo conteúdo aprovado como uma unidade.",
        years_experience: 12,
        whatsapp: account.phone_e164,
        instagram: "",
        youtube: ""
      }
    )
    pending = profile.reload.working_revision
    expect(PublicProfessionalProfileSerializer.new(profile).as_json).to eq(original_public)

    decide(pending, "approved")

    expect(original.reload.status).to eq("superseded")
    expect(profile.reload.published_revision).to eq(pending)
    expect(PublicProfessionalProfileSerializer.new(profile).as_json).to include(
      displayName: "Ana Obras",
      headline: "Projetos elétricos residenciais."
    )
  end

  it "keeps the previous public snapshot and returns private rejection guidance to the owner" do
    publish_initial_revision
    approved_public = PublicProfessionalProfileSerializer.new(profile.reload).as_json
    ProfessionalProfileIdentityUpdater.new.call(
      profile:,
      attributes: {
        display_name: "Ana Obras",
        headline: "Alteração pendente.",
        bio: "Texto pendente para uma nova revisão.",
        years_experience: 12,
        whatsapp: account.phone_e164,
        instagram: "",
        youtube: ""
      }
    )
    pending = profile.reload.working_revision

    decide(pending, "rejected", reason: "Explique melhor os serviços oferecidos no texto.")

    expect(pending.reload).to have_attributes(
      status: "rejected",
      rejection_reason: "Explique melhor os serviços oferecidos no texto."
    )
    expect(profile.reload.profile_status).to eq("published")
    expect(PublicProfessionalProfileSerializer.new(profile).as_json).to eq(approved_public)
    expect(ProfessionalWorkspaceSerializer.new(profile).as_json.dig(:profile, :revision_rejection_reason)).to eq(
      "Explique melhor os serviços oferecidos no texto."
    )
  end

  it "hides and restores public availability without destroying the approved snapshot" do
    revision = publish_initial_revision

    decide(revision, "hidden", reason: "Suspensão preventiva solicitada pela operação.")
    expect(profile.reload.profile_status).to eq("suspended")
    expect(profile.published_revision).to eq(revision)
    expect(PublicProfessionalProfileSerializer.new(profile).as_json).to be_nil

    decide(revision, "restored")
    expect(profile.reload.profile_status).to eq("published")
    expect(profile.published_revision).to eq(revision)
    expect(PublicProfessionalProfileSerializer.new(profile).as_json).to include(displayName: "Ana Souza")
    expect(ModerationAction.order(:created_at).pluck(:action)).to eq(%w[approved hidden restored])
  end

  private

  def decide(revision, action, reason: nil)
    ModerationDecision.new(context:).call(
      target_type: "profile_revision",
      target_id: revision.id,
      action:,
      reason:
    )
  end

  def publish_initial_revision
    revision = profile.working_revision
    select_service(revision, slug: "eletricista-publicado")
    revision.professional_profile_service_areas.create!(city_code: "Joinville")
    revision.update!(status: "pending_review", submitted_at: Time.current)
    decide(revision, "approved")
    revision
  end

  def select_service(revision, slug:)
    category = ServiceCategory.find_or_create_by!(slug: "perfil-moderacao") do |record|
      record.name = "Perfil Moderação"
      record.icon = "i-lucide-wrench"
      record.is_active = true
      record.sort_order = 0
    end
    service = Service.create!(
      category:,
      name: slug.humanize,
      slug:,
      icon: "i-lucide-zap",
      description: "Instalações elétricas.",
      aliases: [],
      is_active: true,
      sort_order: 0
    )
    revision.professional_profile_services.create!(service:, is_primary: true)
    service
  end
end
