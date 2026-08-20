# frozen_string_literal: true

require "rails_helper"

RSpec.describe ModerationQueueQuery do
  let(:profile) { create_profile(phone: "+5547999998202", name: "Ana Souza") }
  let(:service) { create_selected_service(profile) }

  it "combines every review family oldest first without exposing storage keys" do
    revision = profile.working_revision
    revision.update!(status: "pending_review", submitted_at: 4.hours.ago)
    photo = create_photo(profile:, submitted_at: 3.hours.ago)
    item = create_item(profile:, service:, submitted_at: 2.hours.ago)
    verification = create_verification(profile:, submitted_at: 1.hour.ago)

    result = described_class.new.call

    expect(result[:items].map { |entry| entry[:target_id] }).to eq(
      [revision.id, photo.id, item.id, verification.id]
    )
    expect(result[:items].map { |entry| entry[:target_type] }).to eq(
      %w[profile_revision profile_photo portfolio_item verification_request]
    )
    expect(result[:summary]).to include(pending_count: 4)
    expect(result.to_json).not_to include("private_key", "sanitized/", "public_key")
  end

  it "filters, searches accent-insensitively, and paginates the safe presentation" do
    create_item(profile:, service:, title: "Instalação elétrica", submitted_at: 2.hours.ago)
    second = create_item(profile:, service:, title: "Quadro novo", submitted_at: 1.hour.ago)

    searched = described_class.new.call(type: "portfolio_item", search: "instalacao")
    paged = described_class.new.call(type: "portfolio_item", page: 2, per_page: 1)

    expect(searched[:items].sole.fetch(:title)).to include("Instalação elétrica")
    expect(paged[:items].sole.fetch(:target_id)).to eq(second.id)
    expect(paged[:meta]).to eq(page: 2, per_page: 1, total_count: 2, total_pages: 2)
  end

  it "presents accepted relationships by their recorded moderation state" do
    partner = create_profile(phone: "+5547999998204", name: "Beto Lima")
    relationship = ProfessionalRelationship.create!(
      initiator_professional: partner,
      recipient_professional: profile,
      relationship_type: "recommendation",
      context_note: "A parceria foi confirmada pelo profissional.",
      status: "accepted",
      responded_at: 30.minutes.ago
    )

    pending = described_class.new.call(type: "professional_relationship")
    expect(pending[:items].sole).to include(
      target_id: relationship.id,
      status: "pending_review",
      title: "Relação profissional · Beto Lima e Ana Souza",
      subtitle: "Recomendação",
      preview: "A parceria foi confirmada pelo profissional."
    )
    expect(pending[:summary]).to include(pending_count: 1)

    moderate(relationship, "approved")
    expect(
      described_class.new.call(type: "professional_relationship", status: "approved")[:items].sole
    ).to include(target_id: relationship.id, status: "approved")

    moderate(relationship, "hidden", reason: "Conteúdo ocultado para uma nova revisão operacional.")
    expect(
      described_class.new.call(type: "professional_relationship", status: "hidden")[:items].sole
    ).to include(target_id: relationship.id, status: "hidden")
    expect(described_class.new.call[:summary]).to include(pending_count: 0)
  end

  it "rejects unknown or unbounded filters" do
    expect do
      described_class.new.call(type: "relationship", status: "waiting", search: "x" * 101, page: 0, per_page: 51)
    end.to raise_error(described_class::Invalid) { |error|
      expect(error.field_errors.keys).to contain_exactly(:type, :status, :search, :page, :per_page)
    }
  end

  private

  def create_profile(phone:, name:)
    account = UserAccount.create!(phone_e164: phone, role: "professional", status: "active")
    ProfessionalProfile.create!(user_account: account, display_name: name)
  end

  def moderate(relationship, action, reason: nil)
    admin = UserAccount.create!(
      email: "queue-#{SecureRandom.hex(4)}@example.com",
      password: "a-secure-admin-password",
      password_confirmation: "a-secure-admin-password",
      role: "admin",
      status: "active"
    )
    ModerationDecision.new(
      context: AdminActionContext.new(
        admin_user_id: admin.id,
        request_id: "queue-relationship-#{SecureRandom.hex(4)}"
      )
    ).call(
      target_type: "professional_relationship",
      target_id: relationship.id,
      action:,
      reason:
    )
  end

  def create_selected_service(profile)
    category = ServiceCategory.create!(
      name: "Moderação",
      slug: "moderacao-queue",
      icon: "i-lucide-wrench",
      is_active: true,
      sort_order: 0
    )
    created = Service.create!(
      category:,
      name: "Eletricista",
      slug: "eletricista-moderacao-queue",
      icon: "i-lucide-zap",
      description: "Instalações elétricas.",
      aliases: [],
      is_active: true,
      sort_order: 0
    )
    ProfessionalProfileService.create!(
      professional_profile_revision: profile.working_revision,
      service: created,
      is_primary: true
    )
    ProfessionalProfileServiceArea.create!(
      professional_profile_revision: profile.working_revision,
      neighborhood_code: nil
    )
    created
  end

  def create_upload(profile:, purpose:, content_type: "image/png")
    MediaUpload.create!(
      professional_profile: profile,
      purpose:,
      state: "processed",
      declared_content_type: content_type,
      declared_byte_size: 120,
      actual_content_type: content_type,
      sanitized_content_type: content_type,
      actual_byte_size: 120,
      sanitized_byte_size: 100,
      width: 640,
      height: 960,
      quarantine_key: "quarantine/#{profile.id}/#{SecureRandom.uuid}",
      sanitized_key: "sanitized/#{profile.id}/#{SecureRandom.uuid}.png",
      authorization_expires_at: 5.minutes.from_now,
      uploaded_at: 1.minute.ago,
      processed_at: Time.current
    )
  end

  def create_photo(profile:, submitted_at:)
    upload = create_upload(profile:, purpose: "profile_photo", content_type: "image/jpeg")
    profile.profile_photos.create!(
      media_upload: upload,
      status: "pending_review",
      private_key: upload.sanitized_key,
      content_type: "image/jpeg",
      byte_size: 100,
      width: 640,
      height: 960,
      submitted_at:
    )
  end

  def create_item(profile:, service:, submitted_at:, title: "Cozinha iluminada")
    upload = create_upload(profile:, purpose: "portfolio_image")
    profile.portfolio_items.create!(
      media_upload: upload,
      service:,
      title:,
      status: "pending_review",
      private_key: upload.sanitized_key,
      content_type: "image/png",
      byte_size: 100,
      width: 640,
      height: 380,
      submitted_at:
    )
  end

  def create_verification(profile:, submitted_at:)
    upload = create_upload(profile:, purpose: "verification_identity")
    record = profile.verification_requests.create!(
      verification_type: "identity",
      status: "pending_review",
      submitted_at:
    )
    record.create_verification_file!(
      media_upload: upload,
      private_key: upload.sanitized_key,
      content_type: "image/png",
      byte_size: 100,
      width: 640,
      height: 960,
      uploaded_at: submitted_at
    )
    record
  end
end
