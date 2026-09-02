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

  def stub_generate(headline:, bio_intro:, bio_benefit:)
    response = Llm::Client::Response.new(
      payload: {"headline" => headline, "bio_intro" => bio_intro, "bio_benefit" => bio_benefit},
      raw_response: "{}",
      provider_request_id: "req_copy",
      input_tokens: 10,
      cached_input_tokens: 0,
      output_tokens: 5,
      latency_ms: 20
    )
    allow(client).to receive(:generate).and_return(response)
  end

  it "joins the two bio paragraphs with a real blank line, guaranteed regardless of model behavior" do
    stub_generate(
      headline: "Eletricista em Joinville",
      bio_intro: "Ofereço serviços elétricos em Joinville.",
      bio_benefit: "Resolvo sua necessidade com praticidade. Fale comigo."
    )

    described_class.new(client:, settings:).call(revision:)

    expect(revision.reload.ai_bio).to eq(
      "Ofereço serviços elétricos em Joinville.\n\nResolvo sua necessidade com praticidade. Fale comigo."
    )
    expect(revision.ai_copy_model).to eq("gpt-5-mini")
    expect(revision.ai_copy_generated_at).to be_present
  end

  it "clamps the headline and the combined bio to their maximum lengths" do
    stub_generate(headline: "H" * 200, bio_intro: "I" * 700, bio_benefit: "B" * 700)

    described_class.new(client:, settings:).call(revision:)

    revision.reload
    expect(revision.ai_headline.length).to be <= 120
    expect(revision.ai_bio.length).to be <= 1000
  end

  it "sends a deterministic fake payload built from the revision, not the published profile" do
    stub_generate(headline: "x", bio_intro: "x", bio_benefit: "x")

    described_class.new(client:, settings:).call(revision:)

    expect(client).to have_received(:generate).with(
      hash_including(
        fake_payload: {
          "headline" => "Eletricista AI Copy em Joinville com 6 anos de experiência",
          "bio_intro" => "Ofereço serviços como Eletricista AI Copy em Joinville.",
          "bio_benefit" => "Isso ajuda você a resolver sua necessidade com praticidade e tranquilidade. Fale comigo para saber mais."
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

  it "does not persist when the headline is blank" do
    stub_generate(headline: "   ", bio_intro: "Ofereço serviços elétricos.", bio_benefit: "Fale comigo.")

    described_class.new(client:, settings:).call(revision:)

    expect(revision.reload.ai_headline).to be_nil
    expect(revision.reload.ai_bio).to be_nil
  end

  it "does not persist when either bio paragraph is blank" do
    stub_generate(headline: "Eletricista em Joinville", bio_intro: "   ", bio_benefit: "Fale comigo.")

    described_class.new(client:, settings:).call(revision:)

    expect(revision.reload.ai_headline).to be_nil
    expect(revision.reload.ai_bio).to be_nil
  end
end
