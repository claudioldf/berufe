# frozen_string_literal: true

require "rails_helper"

RSpec.describe ModerationDecision do
  let(:admin) do
    UserAccount.create!(
      email: "moderation-decision@example.com",
      password: "a-secure-admin-password",
      password_confirmation: "a-secure-admin-password",
      role: "admin",
      status: "active"
    )
  end
  let(:account) { UserAccount.create!(phone_e164: "+5547999998203", role: "professional", status: "active") }
  let(:profile) { ProfessionalProfile.create!(user_account: account, display_name: "Ana Souza") }
  let(:context) { AdminActionContext.new(admin_user_id: admin.id, request_id: "moderation-decision") }

  it "commits the target transition and immutable action together" do
    revision = profile.working_revision
    revision.update!(status: "pending_review", submitted_at: Time.current)
    profile.update!(profile_status: "published", published_revision: revision, published_at: Time.current)

    described_class.new(context:).call(
      target_type: "profile_revision",
      target_id: revision.id,
      action: "approved",
      note: "Perfil conferido."
    )

    expect(revision.reload.status).to eq("approved")
    expect(profile.reload).to have_attributes(
      profile_status: "published",
      published_revision_id: revision.id,
      approved_revision_id: revision.id
    )
    expect(ModerationAction.sole).to have_attributes(
      admin_user: admin,
      target_type: "profile_revision",
      target_id: revision.id,
      action: "approved",
      note: "Perfil conferido.",
      request_id: "moderation-decision"
    )
  end

  it "rolls back the transition when the audit append fails" do
    revision = profile.working_revision
    revision.update!(status: "pending_review", submitted_at: Time.current)
    profile.update!(profile_status: "published", published_revision: revision, published_at: Time.current)
    allow(ModerationAction).to receive(:create!).and_raise(ActiveRecord::RecordInvalid.new(ModerationAction.new))

    expect do
      described_class.new(context:).call(
        target_type: "profile_revision",
        target_id: revision.id,
        action: "approved"
      )
    end.to raise_error(described_class::Invalid)

    expect(revision.reload.status).to eq("pending_review")
    expect(profile.reload).to have_attributes(profile_status: "published", published_revision: revision)
    expect(ModerationAction.count).to eq(0)
  end

  it "requires private reasons and rejects stale transitions without appending an action" do
    revision = profile.working_revision
    revision.update!(status: "pending_review", submitted_at: Time.current)
    profile.update!(profile_status: "published", published_revision: revision, published_at: Time.current)

    expect do
      described_class.new(context:).call(
        target_type: "profile_revision",
        target_id: revision.id,
        action: "rejected",
        reason: "curto"
      )
    end.to raise_error(described_class::Invalid)

    revision.update!(status: "approved", reviewed_at: Time.current)
    expect do
      described_class.new(context:).call(
        target_type: "profile_revision",
        target_id: revision.id,
        action: "approved"
      )
    end.to raise_error(described_class::Conflict)
    expect(ModerationAction.count).to eq(0)
  end

  it "does not resolve professional relationships as moderation targets" do
    recipient_account = UserAccount.create!(
      phone_e164: "+5547999998204",
      role: "professional",
      status: "active"
    )
    relationship = ProfessionalRelationship.create!(
      initiator_professional: profile,
      recipient_professional: ProfessionalProfile.create!(
        user_account: recipient_account,
        display_name: "Beto Lima"
      ),
      relationship_type: "worked_together",
      status: "accepted",
      responded_at: Time.current
    )

    expect do
      described_class.new(context:).call(
        target_type: "professional_relationship",
        target_id: relationship.id,
        action: "approved"
      )
    end.to raise_error(ActiveRecord::RecordNotFound)
    expect(ModerationAction.count).to eq(0)
  end
end
