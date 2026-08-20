# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Professional profile photo moderation" do
  let(:admin) do
    UserAccount.create!(
      email: "photo-moderation@example.com",
      password: "a-secure-admin-password",
      password_confirmation: "a-secure-admin-password",
      role: "admin",
      status: "active"
    )
  end
  let(:account) { UserAccount.create!(phone_e164: "+5547999998299", role: "professional", status: "active") }
  let(:profile) { ProfessionalProfile.create!(user_account: account, display_name: "Ana Souza", birthdate: Date.new(1990, 4, 12)) }
  let(:context) { AdminActionContext.new(admin_user_id: admin.id, request_id: SecureRandom.hex(8)) }
  let(:publisher) do
    instance_double(ModerationMediaPublisher, delete: nil).tap do |fake|
      allow(fake).to receive(:publish) do |target:, target_type:|
        "moderation/#{target_type}/#{target.id}/reviewed.jpg"
      end
    end
  end

  before { publish_profile_without_photo }

  it "marks the current photo reviewed without changing its public identifier" do
    photo = attach_pending_photo
    public_url = PublicProfilePhotoImageUrl.call(photo)

    decide(photo, "approved")

    expect(photo.reload).to have_attributes(status: "approved")
    expect(profile.reload).to have_attributes(published_photo: photo, approved_photo: photo)
    expect(PublicProfilePhotoImageUrl.call(photo)).to eq(public_url)
  end

  it "rolls a rejected replacement back to the last reviewed photo" do
    approved = attach_pending_photo
    decide(approved, "approved")
    replacement = attach_pending_photo

    decide(replacement, "rejected", reason: "A nova foto contém conteúdo inadequado para o perfil.")

    expect(replacement.reload.status).to eq("rejected")
    expect(profile.reload).to have_attributes(published_photo: approved, approved_photo: approved)
    expect(profile).to be_publicly_available
  end

  it "makes the profile unavailable when its first photo is rejected" do
    photo = attach_pending_photo

    decide(photo, "rejected", reason: "A foto não representa uma pessoa e precisa ser substituída.")

    expect(profile.reload).to have_attributes(published_photo: nil, approved_photo: nil)
    expect(profile).not_to be_publicly_available
  end

  private

  def decide(photo, action, reason: nil)
    ModerationDecision.new(context:, publisher:).call(
      target_type: "profile_photo",
      target_id: photo.id,
      action:,
      reason:
    )
  end

  def publish_profile_without_photo
    category = ServiceCategory.create!(
      name: "Foto Moderação",
      slug: "foto-moderacao",
      icon: "i-lucide-wrench",
      is_active: true,
      sort_order: 0
    )
    service = Service.create!(
      category:,
      name: "Eletricista Foto",
      slug: "eletricista-foto",
      icon: "i-lucide-zap",
      description: "Instalações elétricas.",
      aliases: [],
      is_active: true,
      sort_order: 0
    )
    revision = profile.working_revision
    revision.professional_profile_services.create!(service:, is_primary: true)
    revision.professional_profile_service_areas.create!(city_code: "Joinville")
    revision.update!(status: "approved", submitted_at: Time.current, reviewed_at: Time.current)
    profile.update!(
      profile_status: "published",
      published_at: Time.current,
      published_revision: revision,
      approved_revision: revision
    )
  end

  def attach_pending_photo
    upload = MediaUpload.create!(
      professional_profile: profile,
      purpose: "profile_photo",
      state: "processed",
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
      processed_at: Time.current
    )
    ProfessionalProfilePhotoAttacher.new.call(profile: profile.reload, media_upload_id: upload.id)
  end
end
