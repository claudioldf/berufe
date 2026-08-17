# frozen_string_literal: true

require "rails_helper"

RSpec.describe PublicProfileViewRecorder do
  include ActiveSupport::Testing::TimeHelpers

  let(:account) { UserAccount.create!(phone_e164: "+5547999997603", role: "professional", status: "active") }
  let(:profile) { ProfessionalProfile.create!(user_account: account, display_name: "Perfil Visto") }
  let(:category) do
    ServiceCategory.create!(
      name: "Visualização pública",
      slug: "visualizacao-publica",
      icon: "i-lucide-wrench",
      is_active: true,
      sort_order: 0
    )
  end
  let(:service) do
    Service.create!(
      category:,
      name: "Eletricista visualizado",
      slug: "eletricista-visualizado",
      icon: "i-lucide-zap",
      description: "Serviço visualizado.",
      aliases: [],
      is_active: true,
      sort_order: 0
    )
  end
  let(:event) do
    SearchEvent.create!(
      service:,
      query_text_normalized: "eletricista visualizado",
      city_code: "Joinville",
      result_count: 1
    )
  end
  let(:interaction) do
    PublicProfileInteractionToken::Context.new(
      interaction_id: SecureRandom.uuid,
      professional_id: profile.id,
      service_id: service.id,
      search_event_id: event.id
    )
  end
  let(:cache) { ActiveSupport::Cache::MemoryStore.new(size: 1.megabyte) }
  let(:deduplicator) { PublicInteractionDeduplicator.new(cache:) }
  let(:logger) { instance_double(ActiveSupport::Logger, error: nil) }
  let(:recorder) { described_class.new(deduplicator:, logger:) }

  after { travel_back }

  it "increments once per signed interaction on the local date and marks its search once" do
    travel_to(Time.zone.parse("2026-08-17 02:30:00 UTC")) do
      expect(recorder.call(profile:, interaction:)).to be(true)
      expect(recorder.call(profile:, interaction:)).to be(false)
    end

    expect(ProfessionalDailyMetric.sole).to have_attributes(
      professional: profile,
      metric_date: Date.new(2026, 8, 16),
      profile_views: 1
    )
    expect(event.reload.profile_opened).to be(true)
    expect(logger).not_to have_received(:error)
  end

  it "counts another profile interaction without increasing the search-level numerator again" do
    expect(recorder.call(profile:, interaction:)).to be(true)
    second = interaction.with(interaction_id: SecureRandom.uuid)
    expect(recorder.call(profile:, interaction: second)).to be(true)

    expect(ProfessionalDailyMetric.sole.profile_views).to eq(2)
    expect(SearchEvent.where(id: event.id, profile_opened: true).count).to eq(1)
  end

  it "logs safely, releases the retry claim, and suppresses persistence/cache failures" do
    failing_metrics = class_double(ProfessionalDailyMetric)
    allow(failing_metrics).to receive(:increment_profile_views!).and_raise(ActiveRecord::ConnectionNotEstablished)
    failing_recorder = described_class.new(deduplicator:, metrics: failing_metrics, logger:)

    expect(failing_recorder.call(profile:, interaction:)).to be(false)
    expect(failing_recorder.call(profile:, interaction:)).to be(false)
    expect(failing_metrics).to have_received(:increment_profile_views!).twice
    expect(logger).to have_received(:error).with(
      "public_profile_view_recording_failed class=ActiveRecord::ConnectionNotEstablished"
    ).twice

    broken_cache = instance_double(ActiveSupport::Cache::MemoryStore)
    allow(broken_cache).to receive(:write).and_raise(StandardError, "cache unavailable")
    cache_failure = described_class.new(
      deduplicator: PublicInteractionDeduplicator.new(cache: broken_cache),
      logger:
    )
    expect(cache_failure.call(profile:, interaction: interaction.with(interaction_id: SecureRandom.uuid))).to be(false)
    expect(ProfessionalDailyMetric.count).to eq(0)
    expect(logger).to have_received(:error).with("public_profile_view_recording_failed class=StandardError")
  end
end
