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

  it "keeps revision versions unique per profile" do
    profile = ProfessionalProfile.create!(user_account: first_account, display_name: "Ana Souza")

    expect do
      profile.revisions.create!(version: 1, profile_type: "self_service", display_name: "Ana Souza")
    end.to raise_error(ActiveRecord::RecordInvalid)
  end

  it "accepts a 2,500-character biography and rejects longer content" do
    profile = ProfessionalProfile.create!(user_account: first_account, display_name: "Ana Souza")
    revision = profile.working_revision

    revision.bio = "B" * 2500
    expect(revision).to be_valid

    revision.bio = "B" * 2501
    expect(revision).not_to be_valid
    expect(revision.errors[:bio]).to be_present
  end

  it "enforces the 2,500-character biography limit in PostgreSQL" do
    profile = ProfessionalProfile.create!(user_account: first_account, display_name: "Ana Souza")
    revision = profile.working_revision

    revision.update_columns(bio: "B" * 2500)
    expect(revision.reload.bio.length).to eq(2500)

    expect do
      described_class.where(id: revision.id).update_all(bio: "B" * 2501)
    end.to raise_error(ActiveRecord::StatementInvalid)
  end

  it "rejects revision pointers that belong to another profile" do
    first = ProfessionalProfile.create!(user_account: first_account, display_name: "Ana Souza")
    second = ProfessionalProfile.create!(user_account: second_account, display_name: "Bia Lima")

    expect(first.update(working_revision: second.working_revision)).to be(false)
    expect(first.errors[:base]).to be_present
  end
end
