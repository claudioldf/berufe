# frozen_string_literal: true

require "rails_helper"

RSpec.describe ProfessionalHeadlineBioGenerationJob do
  let(:account) do
    UserAccount.create!(phone_e164: "+5547999996701", role: "professional", status: "active")
  end
  let(:profile) do
    ProfessionalProfile.create!(user_account: account, display_name: "Ana Souza")
  end
  let(:generator) { instance_double(ProfessionalHeadlineBioAiGenerator) }

  it "calls the generator when the revision is missing a headline or a bio" do
    revision = profile.working_revision
    allow(generator).to receive(:call)

    described_class.perform_now(revision.id, generator:)

    expect(generator).to have_received(:call).with(revision:)
  end

  it "does not call the generator once both fields are already authored" do
    revision = profile.working_revision
    revision.update!(headline: "Já escrevi minha frase.", bio: "Já escrevi minha bio.")
    allow(generator).to receive(:call)

    described_class.perform_now(revision.id, generator:)

    expect(generator).not_to have_received(:call)
  end

  it "does nothing when the revision no longer exists" do
    allow(generator).to receive(:call)

    described_class.perform_now(SecureRandom.uuid, generator:)

    expect(generator).not_to have_received(:call)
  end
end
