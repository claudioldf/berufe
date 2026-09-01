# frozen_string_literal: true

require "rails_helper"

RSpec.describe PublicProfileInteractionIssuer do
  let(:category) do
    ServiceCategory.create!(
      name: "Interação de perfil",
      slug: "interacao-de-perfil",
      icon: "i-lucide-wrench",
      is_active: true,
      sort_order: 0
    )
  end
  let(:primary_service) { create_service("Serviço principal", "servico-principal", 0) }
  let(:matching_service) { create_service("Serviço buscado", "servico-buscado", 1) }
  let(:profile) do
    account = UserAccount.create!(phone_e164: "+5547999997602", role: "professional", status: "active")
    record = ProfessionalProfile.create!(user_account: account, display_name: "Perfil Interação")
    revision = record.working_revision
    revision.professional_profile_services.create!(service: primary_service, is_primary: true)
    revision.professional_profile_services.create!(service: matching_service, is_primary: false)
    record.update!(profile_status: "published", published_revision: revision)
    record
  end

  it "carries valid matching search context into a profile-bound interaction" do
    event_id = SecureRandom.uuid
    search_token = PublicInteractionToken.new.issue(
      search_event_id: event_id,
      service_id: matching_service.id
    )

    token = described_class.new.call(profile:, search_token:)

    expect(PublicProfileInteractionToken.new.verify(token)).to have_attributes(
      professional_id: profile.id,
      service_id: matching_service.id,
      search_event_id: event_id
    )
  end

  it "falls back to the primary service without attaching invalid or unrelated search context" do
    unrelated = create_service("Serviço alheio", "servico-alheio", 2)
    search_token = PublicInteractionToken.new.issue(
      search_event_id: SecureRandom.uuid,
      service_id: unrelated.id
    )

    unrelated_context = PublicProfileInteractionToken.new.verify(
      described_class.new.call(profile:, search_token:)
    )
    invalid_context = PublicProfileInteractionToken.new.verify(
      described_class.new.call(profile:, search_token: "invalid")
    )

    expect(unrelated_context).to have_attributes(
      professional_id: profile.id,
      service_id: primary_service.id,
      search_event_id: nil
    )
    expect(invalid_context).to have_attributes(
      service_id: primary_service.id,
      search_event_id: nil
    )
  end

  private

  def create_service(name, slug, sort_order)
    Service.create!(
      category:,
      name:,
      slug:,
      icon: "i-lucide-wrench",
      description: "Serviço para interação pública.",
      aliases: [],
      is_active: true,
      sort_order:
    )
  end
end
