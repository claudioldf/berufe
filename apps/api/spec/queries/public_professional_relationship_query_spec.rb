# frozen_string_literal: true

require "rails_helper"

RSpec.describe PublicProfessionalRelationshipQuery do
  let(:initiator) { create_published_profile("+5547999997101", "Ana Pública") }
  let(:recipient) { create_published_profile("+5547999997102", "Beto Público") }

  it "returns a recipient-accepted relationship for both endpoints without moderation" do
    relationship = create_relationship

    expect(described_class.for_professional(initiator.id)).to contain_exactly(relationship)
    expect(described_class.for_professional(recipient.id)).to contain_exactly(relationship)
    expect(ModerationAction.count).to eq(0)
  end

  it "excludes unanswered relationships and relationships with a non-public endpoint" do
    accepted = create_relationship
    expect(described_class.call).to contain_exactly(accepted)

    recipient.user_account.update!(status: "suspended")
    expect(described_class.call).to be_empty

    accepted.update!(status: "declined")
    expect(described_class.call).to be_empty
  end

  it "excludes declined and pending relationships" do
    declined = ProfessionalRelationship.create!(
      initiator_professional: recipient,
      recipient_professional: initiator,
      relationship_type: "recommendation",
      status: "declined",
      responded_at: 2.minutes.ago
    )
    pending = ProfessionalRelationship.create!(
      initiator_professional: recipient,
      recipient_professional: initiator,
      relationship_type: "worked_together",
      status: "pending"
    )

    expect(described_class.call).to be_empty
    expect([declined, pending]).to all(be_persisted)
  end

  private

  def create_published_profile(phone, name)
    account = UserAccount.create!(phone_e164: phone, role: "professional", status: "active")
    profile = ProfessionalProfile.create!(user_account: account, display_name: name)
    revision = profile.working_revision
    category = ServiceCategory.find_or_create_by!(slug: "relacionamentos-publicos") do |record|
      record.name = "Relacionamentos Públicos"
      record.icon = "i-lucide-wrench"
      record.is_active = true
      record.sort_order = 0
    end
    service = Service.create!(
      category:,
      name: "Serviço #{name}",
      slug: "servico-#{phone.last(4)}",
      icon: "i-lucide-wrench",
      description: "Serviço profissional.",
      aliases: [],
      is_active: true,
      sort_order: 0
    )
    revision.professional_profile_services.create!(service:, is_primary: true)
    revision.professional_profile_service_areas.create!(city_code: "Joinville")
    revision.update!(status: "approved", reviewed_at: Time.current)
    photo = create_approved_photo(profile)
    profile.update!(
      birthdate: Date.new(1990, 4, 12),
      profile_status: "published",
      published_revision: revision,
      approved_revision: revision,
      working_photo: photo,
      published_photo: photo,
      approved_photo: photo
    )
    profile
  end

  def create_approved_photo(profile)
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

  def create_relationship
    ProfessionalRelationship.create!(
      initiator_professional: initiator,
      recipient_professional: recipient,
      relationship_type: "worked_together",
      status: "accepted",
      responded_at: 3.minutes.ago
    )
  end
end
