# frozen_string_literal: true

require "rails_helper"

RSpec.describe ProfessionalProfileRevision, type: :model do
  let(:first_account) do
    UserAccount.create!(phone_e164: "+5547999996501", role: "professional", status: "active")
  end
  let(:second_account) do
    UserAccount.create!(phone_e164: "+5547999996502", role: "professional", status: "active")
  end

  it "creates one initial revision and an immutable collision-safe slug" do
    first = ProfessionalProfile.create!(user_account: first_account, display_name: "João Reparos")
    second = ProfessionalProfile.create!(user_account: second_account, display_name: "João Reparos")

    expect(first.public_slug).to eq("joao-reparos")
    expect(second.public_slug).to match(/\Ajoao-reparos-[a-f0-9]{6}\z/)
    expect(first.working_revision).to have_attributes(
      version: 1,
      status: "draft",
      display_name: "João Reparos"
    )

    ProfessionalProfileIdentityUpdater.new.call(
      profile: first,
      attributes: {
        display_name: "João Obras",
        birthdate: "1990-04-12",
        headline: "Reparos residenciais.",
        bio: "Atendimento em Joinville.",
        whatsapp: first_account.phone_e164,
        instagram: nil,
        youtube: nil
      }
    )
    expect(first.reload.public_slug).to eq("joao-reparos")
  end

  it "allows at most one draft or pending revision per profile" do
    profile = ProfessionalProfile.create!(user_account: first_account, display_name: "Ana Souza")

    expect do
      profile.revisions.create!(version: 2, status: "pending_review", display_name: "Ana Souza")
    end.to raise_error(ActiveRecord::RecordNotUnique)
  end

  it "rejects revision pointers that belong to another profile" do
    first = ProfessionalProfile.create!(user_account: first_account, display_name: "Ana Souza")
    second = ProfessionalProfile.create!(user_account: second_account, display_name: "Bia Lima")

    expect(first.update(working_revision: second.working_revision)).to be(false)
    expect(first.errors[:base]).to be_present
  end
end
