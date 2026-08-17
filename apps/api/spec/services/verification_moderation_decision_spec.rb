# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Identity-verification moderation" do
  let(:admin) do
    UserAccount.create!(
      email: "verification-moderation@example.com",
      password: "a-secure-admin-password",
      password_confirmation: "a-secure-admin-password",
      role: "admin",
      status: "active"
    )
  end
  let(:account) { UserAccount.create!(phone_e164: "+5547999998209", role: "professional", status: "active") }
  let(:profile) { ProfessionalProfile.create!(user_account: account, display_name: "Ana Souza") }
  let(:context) { AdminActionContext.new(admin_user_id: admin.id, request_id: "verification-moderation") }
  let(:request_record) { create_request }

  before do
    publish_profile
  end

  it "records the reviewer and publishes only the controlled identity label and date" do
    decide(request_record, "approved", note: "Imagem e pessoa conferidas.")

    expect(request_record.reload).to have_attributes(
      status: "approved",
      reviewed_by_user_account: admin,
      review_note: "Imagem e pessoa conferidas.",
      public_label: "Identidade verificada"
    )
    expect(request_record.reviewed_at).to be_present
    expect(request_record.verified_at).to be_present

    public_projection = PublicProfessionalProfileSerializer.new(profile.reload).as_json
    expect(public_projection.fetch(:verification)).to eq(
      phone_confirmed: true,
      identity: {
        label: "Identidade verificada",
        verified_at: request_record.verified_at.iso8601
      }
    )
    expect(public_projection.to_json).not_to include(
      request_record.id,
      request_record.verification_file.id,
      request_record.verification_file.private_key,
      "Imagem e pessoa conferidas."
    )
  end

  it "keeps rejection reasons owner-only and publishes no identity claim" do
    decide(request_record, "rejected", reason: "A imagem enviada não permite conferir a identidade.")

    expect(request_record.reload).to have_attributes(
      status: "rejected",
      reviewed_by_user_account: admin,
      review_note: "A imagem enviada não permite conferir a identidade.",
      public_label: nil,
      verified_at: nil
    )
    owner_projection = ProfessionalWorkspaceSerializer.new(profile.reload).as_json
    expect(owner_projection.dig(:profile, :verification, :current)).to include(
      status: "rejected",
      rejection_reason: "A imagem enviada não permite conferir a identidade."
    )
    public_projection = PublicProfessionalProfileSerializer.new(profile).as_json
    expect(public_projection.fetch(:verification)).to eq(phone_confirmed: true, identity: nil)
    expect(public_projection.to_json).not_to include("A imagem enviada não permite conferir a identidade.")
  end

  it "rejects unsupported hide/restore transitions without changing the request" do
    expect do
      decide(request_record, "hidden", reason: "A ocultação não se aplica a uma verificação.")
    end.to raise_error(ModerationDecision::Conflict)

    expect(request_record.reload.status).to eq("pending_review")
    expect(ModerationAction.count).to eq(0)
  end

  private

  def decide(target, action, reason: nil, note: nil)
    ModerationDecision.new(context:).call(
      target_type: "verification_request",
      target_id: target.id,
      action:,
      reason:,
      note:
    )
  end

  def publish_profile
    revision = profile.working_revision
    revision.update!(status: "approved", reviewed_at: Time.current)
    profile.update!(profile_status: "published", published_revision: revision)
  end

  def create_request
    upload = MediaUpload.create!(
      professional_profile: profile,
      purpose: "verification_identity",
      state: "attached",
      declared_content_type: "image/png",
      declared_byte_size: 120,
      actual_content_type: "image/png",
      sanitized_content_type: "image/png",
      actual_byte_size: 120,
      sanitized_byte_size: 100,
      width: 640,
      height: 960,
      quarantine_key: "quarantine/#{profile.id}/#{SecureRandom.uuid}",
      sanitized_key: "sanitized/#{profile.id}/#{SecureRandom.uuid}.png",
      authorization_expires_at: 5.minutes.from_now,
      uploaded_at: 1.minute.ago,
      processed_at: Time.current,
      attached_at: Time.current
    )
    record = profile.verification_requests.create!(
      verification_type: "identity",
      status: "pending_review",
      submitted_at: Time.current
    )
    record.create_verification_file!(
      media_upload: upload,
      private_key: upload.sanitized_key,
      content_type: "image/png",
      byte_size: 100,
      width: 640,
      height: 960,
      uploaded_at: Time.current
    )
    record
  end
end
