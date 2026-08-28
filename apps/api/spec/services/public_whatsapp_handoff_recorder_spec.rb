# frozen_string_literal: true

require "rails_helper"

RSpec.describe PublicWhatsappHandoffRecorder do
  let(:account) { UserAccount.create!(phone_e164: "+5547999997902", role: "professional", status: "active") }
  let(:profile) { ProfessionalProfile.create!(user_account: account, display_name: "Métrica WhatsApp") }
  let(:service) do
    category = ServiceCategory.create!(
      name: "Métrica WhatsApp",
      slug: "metrica-whatsapp",
      icon: "i-lucide-wrench",
      is_active: true,
      sort_order: 0
    )
    Service.create!(
      category:,
      name: "Eletricista Métrica",
      slug: "eletricista-metrica",
      icon: "i-lucide-zap",
      description: "Serviço para métrica.",
      aliases: [],
      is_active: true,
      sort_order: 0
    )
  end
  let(:search_event) do
    SearchEvent.create!(
      service:,
      query_text_normalized: "eletricista metrica",
      city_code: "4209102",
      result_count: 1
    )
  end
  let(:interaction) do
    PublicWhatsappInteractionResolver::Context.new(
      source: "public_profile",
      interaction_id: SecureRandom.uuid,
      service_id: service.id,
      service_name: service.name,
      search_event_id: search_event.id
    )
  end

  before do
    Rails.application.config.x.berufe.public_interaction_cache.clear
  end

  it "counts one source-aware handoff, marks its search once, and suppresses retries" do
    recorder = described_class.new

    expect(recorder.call(profile:, interaction:)).to be(true)
    expect(recorder.call(profile:, interaction:)).to be(false)

    expect(ProfessionalDailyMetric.sole).to have_attributes(
      whatsapp_clicks: 1,
      whatsapp_clicks_public_profile: 1,
      whatsapp_clicks_search_result: 0
    )
    expect(search_event.reload.whatsapp_handoff_occurred).to be(true)
  end

  it "increments the search-result source and keeps the total invariant" do
    search_interaction = interaction.with(
      source: "search_result",
      interaction_id: SecureRandom.uuid
    )

    described_class.new.call(profile:, interaction:)
    described_class.new.call(profile:, interaction: search_interaction)

    expect(ProfessionalDailyMetric.sole).to have_attributes(
      whatsapp_clicks: 2,
      whatsapp_clicks_public_profile: 1,
      whatsapp_clicks_search_result: 1
    )
  end

  it "logs safely, releases the claim, and allows a retry after persistence failure" do
    allow(ProfessionalDailyMetric).to receive(:increment_whatsapp_clicks!)
      .and_raise(ActiveRecord::ConnectionNotEstablished)
    allow(Rails.logger).to receive(:error)
    recorder = described_class.new

    expect(recorder.call(profile:, interaction:)).to be(false)
    expect(Rails.logger).to have_received(:error).with(
      "public_whatsapp_handoff_recording_failed class=ActiveRecord::ConnectionNotEstablished source=public_profile"
    )

    allow(ProfessionalDailyMetric).to receive(:increment_whatsapp_clicks!).and_call_original
    expect(recorder.call(profile:, interaction:)).to be(true)
  end

  it "contains a cache failure without recording or exposing interaction data" do
    deduplicator = instance_double(PublicInteractionDeduplicator)
    allow(deduplicator).to receive(:claim).and_raise(StandardError, "cache unavailable")
    allow(Rails.logger).to receive(:error)

    expect(described_class.new(deduplicator:).call(profile:, interaction:)).to be(false)
    expect(ProfessionalDailyMetric.count).to eq(0)
    expect(Rails.logger).to have_received(:error).with(
      "public_whatsapp_handoff_recording_failed class=StandardError source=public_profile"
    )
  end
end
