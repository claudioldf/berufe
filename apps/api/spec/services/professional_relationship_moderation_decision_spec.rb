# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Professional relationship moderation decisions" do
  let(:admin) do
    UserAccount.create!(
      email: "relationship-moderation@example.com",
      password: "a-secure-admin-password",
      password_confirmation: "a-secure-admin-password",
      role: "admin",
      status: "active"
    )
  end
  let(:initiator) { create_profile("+5547999997191", "Ana Indicadora") }
  let(:recipient) { create_profile("+5547999997192", "Beto Recomendado") }
  let(:relationship) do
    ProfessionalRelationship.create!(
      initiator_professional: initiator,
      recipient_professional: recipient,
      relationship_type: "recommendation",
      status: "accepted",
      responded_at: Time.current
    )
  end

  it "derives approve, hide, and restore from append-only actions without rewriting acceptance" do
    decide("approved", request_id: "relationship-approve")
    expect(relationship.reload.status).to eq("accepted")
    expect(ProfessionalRelationshipModerationState.call(relationship)).to eq("approved")

    decide(
      "hidden",
      request_id: "relationship-hide",
      reason: "A relação precisa de uma nova revisão operacional."
    )
    expect(relationship.reload.status).to eq("accepted")
    expect(ProfessionalRelationshipModerationState.call(relationship)).to eq("hidden")

    decide("restored", request_id: "relationship-restore")
    expect(relationship.reload.status).to eq("accepted")
    expect(ProfessionalRelationshipModerationState.call(relationship)).to eq("approved")
    expect(ModerationAction.where(target_id: relationship.id).pluck(:action)).to eq(
      %w[approved hidden restored]
    )
  end

  it "allows one initial rejection and rejects stale or non-accepted transitions" do
    decide(
      "rejected",
      request_id: "relationship-reject",
      reason: "O contexto informado não pode ser publicado nesta relação."
    )

    expect(relationship.reload.status).to eq("accepted")
    expect(ProfessionalRelationshipModerationState.call(relationship)).to eq("rejected")
    expect do
      decide("approved", request_id: "relationship-stale")
    end.to raise_error(ModerationDecision::Conflict)

    pending = ProfessionalRelationship.create!(
      initiator_professional: recipient,
      recipient_professional: initiator,
      relationship_type: "worked_together",
      status: "pending"
    )
    expect do
      decision(request_id: "relationship-pending").call(
        target_type: "professional_relationship",
        target_id: pending.id,
        action: "approved"
      )
    end.to raise_error(ModerationDecision::Conflict)
    expect(ModerationAction.where(target_id: pending.id)).to be_empty
  end

  private

  def create_profile(phone, name)
    account = UserAccount.create!(phone_e164: phone, role: "professional", status: "active")
    ProfessionalProfile.create!(user_account: account, display_name: name)
  end

  def decision(request_id:)
    ModerationDecision.new(context: AdminActionContext.new(admin_user_id: admin.id, request_id:))
  end

  def decide(action, request_id:, reason: nil)
    decision(request_id:).call(
      target_type: "professional_relationship",
      target_id: relationship.id,
      action:,
      reason:
    )
  end
end
