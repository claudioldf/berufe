# frozen_string_literal: true

require "rails_helper"

RSpec.describe ProfessionalHeadlineBioAiGenerator do
  let(:account) do
    UserAccount.create!(phone_e164: "+5547999996601", role: "professional", status: "active")
  end
  let(:profile) do
    ProfessionalProfile.create!(user_account: account, display_name: "Ana Souza")
  end
  let(:category) do
    ServiceCategory.create!(
      name: "Reparos AI Copy",
      slug: "reparos-ai-copy",
      icon: "i-lucide-wrench",
      is_active: true,
      sort_order: 0
    )
  end
  let(:service) do
    Service.create!(
      category:,
      name: "Eletricista AI Copy",
      slug: "eletricista-ai-copy",
      icon: "i-lucide-zap",
      description: "Instalações elétricas.",
      aliases: ["elétrica"],
      is_active: true,
      sort_order: 0
    )
  end
  let(:revision) do
    revision = profile.working_revision
    revision.update!(years_experience: 6, coverage_city: joinville_city, covers_whole_city: true)
    revision.professional_profile_services.create!(service:, is_primary: true)
    revision
  end
  let(:settings) { Data.define(:llm_adapter, :openai_model).new(llm_adapter: "fake", openai_model: "gpt-5-mini") }
  let(:client) { instance_double(Llm::Client) }

  it "persists the generated headline and bio, clamped to their maximum lengths" do
    response = Llm::Client::Response.new(
      payload: {"headline" => "H" * 200, "bio" => "B" * 900},
      raw_response: "{}",
      provider_request_id: "req_copy",
      input_tokens: 10,
      cached_input_tokens: 0,
      output_tokens: 5,
      latency_ms: 20
    )
    allow(client).to receive(:generate).and_return(response)

    described_class.new(client:, settings:).call(revision:)

    revision.reload
    expect(revision.ai_headline.length).to be <= 120
    expect(revision.ai_bio.length).to be <= 500
    expect(revision.ai_copy_model).to eq("gpt-5-mini")
    expect(revision.ai_copy_generated_at).to be_present
  end

  it "sends a deterministic fake payload built from the revision, not the published profile" do
    response = Llm::Client::Response.new(
      payload: {"headline" => "Eletricista em Joinville", "bio" => "Ofereço serviços elétricos."},
      raw_response: "{}",
      provider_request_id: nil,
      input_tokens: nil,
      cached_input_tokens: nil,
      output_tokens: nil,
      latency_ms: 0
    )
    allow(client).to receive(:generate).and_return(response)

    described_class.new(client:, settings:).call(revision:)

    expect(client).to have_received(:generate).with(
      hash_including(
        fake_payload: {
          "headline" => "Eletricista AI Copy em Joinville com 6 anos de experiência",
          "bio" => "Ofereço serviços como Eletricista AI Copy em Joinville. Fale comigo para saber mais."
        }
      )
    )
  end

  it "maps provider failures to ProviderUnavailable and reports them without persisting anything" do
    allow(client).to receive(:generate).and_raise(Llm::Client::RateLimited.new(retry_after: 30))
    allow(Rails.error).to receive(:report)

    expect { described_class.new(client:, settings:).call(revision:) }
      .to raise_error(described_class::ProviderUnavailable)
    expect(Rails.error).to have_received(:report)
    expect(revision.reload.ai_headline).to be_nil
  end

  it "does not persist a blank headline or bio" do
    response = Llm::Client::Response.new(
      payload: {"headline" => "   ", "bio" => "Ofereço serviços elétricos."},
      raw_response: "{}",
      provider_request_id: nil,
      input_tokens: nil,
      cached_input_tokens: nil,
      output_tokens: nil,
      latency_ms: 0
    )
    allow(client).to receive(:generate).and_return(response)

    described_class.new(client:, settings:).call(revision:)

    expect(revision.reload.ai_headline).to be_nil
    expect(revision.reload.ai_bio).to be_nil
  end
end
