# frozen_string_literal: true

require "rails_helper"

RSpec.describe PublicProfessionalProfileSerializer do
  let(:account) do
    UserAccount.create!(
      phone_e164: "+5547999996601",
      role: "professional",
      status: "active",
      phone_verified_at: Time.current
    )
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

  it "publishes a material edit immediately while retaining its approved fallback" do
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
    approved.update!(coverage_city: joinville_city, covers_whole_city: true)
    approved.update!(status: "approved", reviewed_at: Time.current)
    photo = create_approved_photo(profile)
    profile.update!(
      birthdate: Date.new(1990, 4, 12),
      profile_status: "published",
      published_revision: approved,
      approved_revision: approved,
      working_photo: photo,
      published_photo: photo,
      approved_photo: photo
    )

    before_edit = described_class.new(profile.reload).as_json
    ProfessionalProfileIdentityUpdater.new.call(
      profile:,
      attributes: {
        display_name: "Ana Obras",
        birthdate: "1990-04-12",
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
    expect(profile.published_revision).to eq(profile.working_revision)
    expect(profile.approved_revision).to eq(approved)
    expect(profile.working_revision.professional_profile_services.sole.service).to eq(service)
    expect(profile.working_revision).to have_attributes(
      coverage_city_code: joinville_city.code,
      covers_whole_city: true
    )
    expect(profile.working_revision.professional_profile_service_areas).to be_empty
    expect(described_class.new(profile).as_json).to include(
      display_name: "Ana Obras",
      headline: "Nova apresentação pendente.",
      bio: "Conteúdo ainda não aprovado."
    )
    expect(before_edit).to include(
      public_slug: "ana-souza",
      display_name: "Ana Souza",
      headline: "Elétrica residencial.",
      verification_labels: [{type: "phone", label: "Telefone confirmado", verified_at: nil}]
    )
  end

  it "excludes a suspended account even when an approved pointer exists" do
    publish(profile)
    account.update!(status: "suspended")

    expect(described_class.new(profile.reload).as_json).to be_nil
  end

  it "projects recommendation authorship from each public profile direction" do
    publish(profile)
    partner_account = UserAccount.create!(
      phone_e164: "+5547999996602",
      role: "professional",
      status: "active"
    )
    partner = ProfessionalProfile.create!(user_account: partner_account, display_name: "Beto Lima")
    publish(partner)
    ProfessionalRelationship.create!(
      initiator_professional: partner,
      recipient_professional: profile,
      relationship_type: "recommendation",
      context_note: "Indicação profissional aprovada.",
      status: "accepted",
      responded_at: Time.current
    )

    received = described_class.new(profile.reload).as_json.fetch(:relationships).sole
    authored = described_class.new(partner.reload).as_json.fetch(:relationships).sole

    expect(received).to include(direction: "incoming")
    expect(received.dig(:professional, :display_name)).to eq("Beto Lima")
    expect(authored).to include(direction: "outgoing")
    expect(authored.dig(:professional, :display_name)).to eq("Ana Souza")
  end

  private

  def publish(public_profile)
    revision = public_profile.working_revision
    category = ServiceCategory.find_or_create_by!(slug: "serializador-publico") do |record|
      record.name = "Serializador Público"
      record.icon = "i-lucide-wrench"
      record.is_active = true
      record.sort_order = 0
    end
    service = Service.create!(
      category:,
      name: "Serviço #{public_profile.id}",
      slug: "servico-#{public_profile.id}",
      icon: "i-lucide-wrench",
      description: "Serviço profissional.",
      aliases: [],
      is_active: true,
      sort_order: 0
    )
    revision.professional_profile_services.create!(service:, is_primary: true)
    revision.update!(coverage_city: joinville_city, covers_whole_city: true)
    revision.update!(status: "approved", reviewed_at: Time.current)
    photo = create_approved_photo(public_profile)
    public_profile.update!(
      birthdate: Date.new(1990, 4, 12),
      profile_status: "published",
      published_revision: revision,
      approved_revision: revision,
      working_photo: photo,
      published_photo: photo,
      approved_photo: photo
    )
  end

  def create_approved_photo(public_profile)
    upload = MediaUpload.create!(
      professional_profile: public_profile,
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
      quarantine_key: "quarantine/#{public_profile.id}/#{SecureRandom.uuid}",
      sanitized_key: "sanitized/#{public_profile.id}/#{SecureRandom.uuid}.jpg",
      authorization_expires_at: 5.minutes.from_now,
      uploaded_at: 1.minute.ago,
      processed_at: Time.current,
      attached_at: Time.current
    )
    public_profile.profile_photos.create!(
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
