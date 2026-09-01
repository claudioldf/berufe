# frozen_string_literal: true

require "rails_helper"

RSpec.describe Admin::ProfessionalPublicationDecision do
  let(:admin) do
    UserAccount.create!(
      email: "professional-publication@example.com",
      password: "a-secure-admin-password",
      password_confirmation: "a-secure-admin-password",
      role: "admin",
      status: "active"
    )
  end
  let(:context) { AdminActionContext.new(admin_user_id: admin.id, request_id: "professional-publication") }
  let(:account) { UserAccount.create!(phone_e164: "+5547999995001", role: "professional", status: "active") }
  let(:profile) { ProfessionalProfile.create!(user_account: account, display_name: "Ana Souza") }

  it "unpublishes a live profile with a user-visible reason and an immutable audit row" do
    make_profile_publicly_eligible(profile)

    described_class.new(context:).call(
      professional_profile_id: profile.id,
      published: false,
      reason: "Denúncia de identidade falsa confirmada pela equipe."
    )

    expect(profile.reload.profile_status).to eq("suspended")
    expect(ModerationAction.sole).to have_attributes(
      admin_user: admin,
      target_type: "professional_profile",
      target_id: profile.id,
      action: "hidden",
      reason: "Denúncia de identidade falsa confirmada pela equipe.",
      request_id: "professional-publication"
    )
  end

  it "republishes a suspended profile without requiring a reason" do
    make_profile_publicly_eligible(profile)
    profile.update!(profile_status: "suspended")

    described_class.new(context:).call(professional_profile_id: profile.id, published: true)

    expect(profile.reload.profile_status).to eq("published")
    expect(ModerationAction.sole).to have_attributes(
      admin_user: admin,
      target_type: "professional_profile",
      target_id: profile.id,
      action: "restored",
      reason: nil,
      request_id: "professional-publication"
    )
  end

  it "rejects unpublishing without a sufficiently long reason" do
    make_profile_publicly_eligible(profile)

    expect do
      described_class.new(context:).call(professional_profile_id: profile.id, published: false, reason: "curto")
    end.to raise_error(described_class::Invalid) do |error|
      expect(error.field_errors.keys).to contain_exactly(:reason)
    end
    expect(profile.reload.profile_status).to eq("published")
    expect(ModerationAction.count).to eq(0)
  end

  it "rejects a non-boolean published value" do
    expect do
      described_class.new(context:).call(professional_profile_id: profile.id, published: "maybe")
    end.to raise_error(described_class::Invalid) do |error|
      expect(error.field_errors.keys).to contain_exactly(:published)
    end
  end

  it "refuses to publish a profile that is not suspended" do
    make_profile_publicly_eligible(profile)

    expect do
      described_class.new(context:).call(professional_profile_id: profile.id, published: true)
    end.to raise_error(described_class::Conflict)
    expect(ModerationAction.count).to eq(0)
  end

  it "refuses to unpublish a profile that is not currently published" do
    expect do
      described_class.new(context:).call(
        professional_profile_id: profile.id, published: false, reason: "Motivo com detalhes suficientes."
      )
    end.to raise_error(described_class::Conflict)
    expect(ModerationAction.count).to eq(0)
  end
end
