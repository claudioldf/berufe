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
      whatsapp_e164: account.phone_e164,
      birthdate: Date.new(1990, 4, 12)
    )
  end
  let(:context) { AdminActionContext.new(admin_user_id: admin.id, request_id: "profile-moderation") }

  it "marks the already-public first revision reviewed without republishing it" do
    revision = publish_pending_revision
    public_before = PublicProfessionalProfileSerializer.new(profile.reload).as_json

    decide(revision, "approved")

    expect(profile.reload).to have_attributes(
      profile_status: "published",
      published_revision: revision,
      approved_revision: revision,
      working_revision: revision
    )
    expect(PublicProfessionalProfileSerializer.new(profile).as_json).to eq(public_before)
  end

  it "updates the rollback pointer when a newer public revision is reviewed" do
    original = approve_first_revision
    first_published_at = profile.reload.published_at

    save_identity(bio: "Novo conteúdo público aguardando revisão.")
    pending = profile.reload.published_revision
    expect(PublicProfessionalProfileSerializer.new(profile).as_json).to include(
      bio: "Novo conteúdo público aguardando revisão."
    )

    decide(pending, "approved")

    expect(original.reload.status).to eq("superseded")
    expect(profile.reload).to have_attributes(published_revision: pending, approved_revision: pending)
    expect(profile.published_at).to eq(first_published_at)
  end

  it "rolls a rejected live revision back to the last reviewed snapshot" do
    approved = approve_first_revision
    approved_public = PublicProfessionalProfileSerializer.new(profile.reload).as_json
    save_identity(bio: "Texto público que será retirado.")
    pending = profile.reload.published_revision

    decide(pending, "rejected", reason: "Explique melhor os serviços oferecidos no texto.")

    expect(pending.reload).to have_attributes(
      status: "rejected",
      rejection_reason: "Explique melhor os serviços oferecidos no texto."
    )
    expect(profile.reload).to have_attributes(
      profile_status: "published",
      published_revision: approved,
      approved_revision: approved,
      working_revision: pending
    )
    expect(PublicProfessionalProfileSerializer.new(profile).as_json).to eq(approved_public)
  end

  it "makes a rejected first revision unavailable when no fallback exists" do
    revision = publish_pending_revision

    decide(revision, "rejected", reason: "O conteúdo precisa ser corrigido antes de permanecer público.")

    expect(profile.reload).to have_attributes(profile_status: "published", published_revision: nil)
    expect(profile).not_to be_publicly_available
    expect(PublicProfessionalProfileSerializer.new(profile).as_json).to be_nil
  end

  private

  def save_identity(bio:)
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

  def decide(revision, action, reason: nil)
    ModerationDecision.new(context:).call(
      target_type: "profile_revision",
      target_id: revision.id,
      action:,
      reason:
    )
  end

  def approve_first_revision
    publish_pending_revision.tap { |revision| decide(revision, "approved") }
  end

  def publish_pending_revision
    revision = profile.working_revision
    unless revision.professional_profile_services.exists?
      revision.professional_profile_services.create!(service: selected_service, is_primary: true)
      revision.update!(coverage_city: joinville_city, covers_whole_city: true)
    end
    revision.update!(status: "pending_review", submitted_at: Time.current)
    photo = approved_photo
    profile.update!(
      profile_status: "published",
      published_at: profile.published_at || Time.current,
      published_revision: revision,
      published_photo: photo,
      approved_photo: photo,
      working_photo: photo
    )
    revision
  end

  def selected_service
    @selected_service ||= begin
      category = ServiceCategory.create!(
        name: "Perfil Moderação",
        slug: "perfil-moderacao",
        icon: "i-lucide-wrench",
        is_active: true,
        sort_order: 0
      )
      Service.create!(
        category:,
        name: "Eletricista Moderação",
        slug: "eletricista-moderacao",
        icon: "i-lucide-zap",
        description: "Instalações elétricas.",
        aliases: [],
        is_active: true,
        sort_order: 0
      )
    end
  end

  def approved_photo
    return @approved_photo if defined?(@approved_photo)

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
    @approved_photo = profile.profile_photos.create!(
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
