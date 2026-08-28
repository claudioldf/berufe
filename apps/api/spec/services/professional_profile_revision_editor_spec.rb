# frozen_string_literal: true

require "rails_helper"

RSpec.describe ProfessionalProfileRevisionEditor do
  let(:account) { UserAccount.create!(phone_e164: "+5547999998311", role: "professional", status: "active") }
  let(:profile) do
    ProfessionalProfile.create!(
      user_account: account,
      display_name: "Ana Souza",
      headline: "Elétrica residencial.",
      bio: "Instalações em Joinville.",
      whatsapp_e164: account.phone_e164
    )
  end
  let!(:approved) { publish_and_approve_profile }

  it "does not create a review item when saved values are unchanged" do
    save_identity

    expect(profile.reload.published_revision).to eq(approved)
    expect(profile.working_revision).to eq(approved)
    expect(profile.revisions.where(status: "pending_review")).to be_empty
  end

  it "makes a material edit public immediately while retaining the approved rollback" do
    save_identity(bio: "Texto novo já publicado enquanto aguarda análise.")

    pending = profile.reload.working_revision
    expect(pending).to have_attributes(status: "pending_review")
    expect(profile.published_revision).to eq(pending)
    expect(profile.approved_revision).to eq(approved)
    expect(PublicProfessionalProfileSerializer.new(profile).as_json).to include(
      bio: "Texto novo já publicado enquanto aguarda análise."
    )
  end

  it "supersedes an older pending revision when the owner saves again" do
    save_identity(bio: "Primeira alteração pública.")
    first_pending = profile.reload.published_revision

    save_identity(bio: "Segunda alteração pública.")

    expect(first_pending.reload.status).to eq("superseded")
    expect(profile.reload.published_revision).to have_attributes(
      status: "pending_review",
      bio: "Segunda alteração pública."
    )
    expect(profile.revisions.where(status: "pending_review").count).to eq(1)
  end

  it "creates a new live revision when correcting rejected content" do
    save_identity(bio: "Conteúdo inadequado.")
    rejected = profile.reload.published_revision
    decide(rejected, "rejected", reason: "Explique melhor os serviços oferecidos no texto.")

    expect(profile.reload.published_revision).to eq(approved)
    save_identity(bio: "Conteúdo corrigido e novamente público.")

    expect(profile.reload.published_revision).to have_attributes(
      status: "pending_review",
      bio: "Conteúdo corrigido e novamente público."
    )
    expect(profile.working_revision).not_to eq(rejected)
  end

  private

  def save_identity(bio: "Instalações em Joinville.")
    ProfessionalProfileIdentityUpdater.new.call(
      profile: profile.reload,
      attributes: {
        display_name: "Ana Souza",
        birthdate: "1990-04-12",
        headline: "Elétrica residencial.",
        bio:,
        years_experience: nil,
        whatsapp: account.phone_e164,
        instagram: "",
        youtube: ""
      }
    )
  end

  def publish_and_approve_profile
    profile.update!(birthdate: Date.new(1990, 4, 12))
    revision = profile.working_revision
    revision.professional_profile_services.create!(service: primary_service, is_primary: true)
    revision.update!(coverage_city: joinville_city, covers_whole_city: true)
    revision.update!(status: "pending_review", submitted_at: Time.current)
    photo = approved_photo
    profile.update!(
      profile_status: "published",
      published_at: Time.current,
      published_revision: revision,
      published_photo: photo,
      approved_photo: photo,
      working_photo: photo
    )
    decide(revision, "approved")
    revision
  end

  def decide(revision, action, reason: nil)
    admin = UserAccount.find_or_create_by!(email: "material-edit@example.com") do |record|
      record.password = "a-secure-admin-password"
      record.password_confirmation = "a-secure-admin-password"
      record.role = "admin"
      record.status = "active"
    end
    ModerationDecision.new(
      context: AdminActionContext.new(admin_user_id: admin.id, request_id: SecureRandom.hex(8))
    ).call(target_type: "profile_revision", target_id: revision.id, action:, reason:)
  end

  def primary_service
    @primary_service ||= begin
      category = ServiceCategory.create!(
        name: "Edição Material",
        slug: "edicao-material",
        icon: "i-lucide-wrench",
        is_active: true,
        sort_order: 0
      )
      Service.create!(
        category:,
        name: "Eletricista Material",
        slug: "eletricista-material",
        icon: "i-lucide-zap",
        description: "Instalações elétricas.",
        aliases: [],
        is_active: true,
        sort_order: 0
      )
    end
  end

  def approved_photo
    upload = MediaUpload.create!(
      professional_profile: profile,
      purpose: "profile_photo",
      state: "attached",
      declared_content_type: "image/jpeg",
      declared_byte_size: 100,
      actual_content_type: "image/jpeg",
      sanitized_content_type: "image/jpeg",
      actual_byte_size: 100,
      sanitized_byte_size: 100,
      width: 640,
      height: 960,
      quarantine_key: "quarantine/#{profile.id}/#{SecureRandom.uuid}",
      sanitized_key: "sanitized/#{profile.id}/#{SecureRandom.uuid}.jpg",
      authorization_expires_at: 5.minutes.from_now,
      uploaded_at: 1.minute.ago,
      processed_at: Time.current,
      attached_at: Time.current
    )
    profile.profile_photos.create!(
      media_upload: upload,
      status: "approved",
      private_key: upload.sanitized_key,
      public_key: "moderation/profile_photo/#{SecureRandom.uuid}.jpg",
      content_type: "image/jpeg",
      byte_size: 100,
      width: 640,
      height: 960,
      submitted_at: Time.current,
      reviewed_at: Time.current
    )
  end
end
