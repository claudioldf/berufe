# frozen_string_literal: true

require "rails_helper"

RSpec.describe PublicWhatsappInteractionResolver do
  let(:category) do
    ServiceCategory.create!(
      name: "Contexto WhatsApp",
      slug: "contexto-whatsapp",
      icon: "i-lucide-wrench",
      is_active: true,
      sort_order: 0
    )
  end
  let(:service) do
    Service.create!(
      category:,
      name: "Eletricista de contexto",
      slug: "eletricista-de-contexto",
      icon: "i-lucide-zap",
      description: "Serviço para resolver contexto.",
      aliases: [],
      is_active: true,
      sort_order: 0
    )
  end
  let(:profile) do
    account = UserAccount.create!(phone_e164: "+5547999997901", role: "professional", status: "active")
    record = ProfessionalProfile.create!(
      user_account: account,
      display_name: "Perfil de Contexto",
      whatsapp_e164: account.phone_e164
    )
    revision = record.working_revision
    revision.professional_profile_services.create!(service:, is_primary: true)
    record.update!(profile_status: "published", published_revision: revision)
    record
  end

  it "resolves profile-bound interactions to an approved service" do
    token = PublicProfileInteractionToken.new.issue(
      professional_id: profile.id,
      service_id: service.id,
      search_event_id: SecureRandom.uuid
    )

    expect(described_class.new.call(profile:, source: "public_profile", token:)).to have_attributes(
      source: "public_profile",
      service_id: service.id,
      service_name: service.name
    )
  end

  it "resolves search interactions only when the selected profile offers the signed service" do
    event_id = SecureRandom.uuid
    token = PublicInteractionToken.new.issue(search_event_id: event_id, service_id: service.id)
    context = described_class.new.call(profile:, source: "search_result", token:)

    expect(context).to have_attributes(
      interaction_id: event_id,
      search_event_id: event_id,
      service_id: service.id
    )

    unrelated_service = Service.create!(
      category:,
      name: "Pintor sem contexto",
      slug: "pintor-sem-contexto",
      icon: "i-lucide-paintbrush",
      description: "Serviço que o perfil não oferece.",
      aliases: [],
      is_active: true,
      sort_order: 1
    )
    unrelated = PublicInteractionToken.new.issue(
      search_event_id: SecureRandom.uuid,
      service_id: unrelated_service.id
    )
    expect do
      described_class.new.call(profile:, source: "search_result", token: unrelated)
    end.to raise_error(described_class::InvalidInteraction)
  end

  it "rejects invalid sources, token kinds, and cross-profile contexts" do
    other_id = SecureRandom.uuid
    profile_token = PublicProfileInteractionToken.new.issue(
      professional_id: other_id,
      service_id: service.id
    )

    [
      ["other", profile_token],
      ["search_result", profile_token],
      ["public_profile", profile_token],
      ["public_profile", "invalid"]
    ].each do |source, token|
      expect do
        described_class.new.call(profile:, source:, token:)
      end.to raise_error(described_class::InvalidInteraction)
    end
  end
end
