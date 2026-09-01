# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Moderation audit records" do
  let(:admin) do
    UserAccount.create!(
      email: "moderation-audit@example.com",
      password: "a-secure-admin-password",
      password_confirmation: "a-secure-admin-password",
      role: "admin",
      status: "active"
    )
  end

  it "keeps moderation decisions immutable and requires a user-visible reason where needed" do
    action = ModerationAction.create!(
      admin_user: admin,
      target_type: "verification_request",
      target_id: SecureRandom.uuid,
      action: "rejected",
      reason: "  Conteúdo ainda não atende aos critérios.  ",
      note: "  Conferido manualmente.  ",
      request_id: "moderation-audit-decision",
      created_at: Time.current
    )

    expect(action).to have_attributes(
      reason: "Conteúdo ainda não atende aos critérios.",
      note: "Conferido manualmente."
    )
    expect { action.update!(note: "alterada") }.to raise_error(ActiveRecord::ReadOnlyRecord)
    expect { action.destroy! }.to raise_error(ActiveRecord::ReadOnlyRecord)

    invalid = ModerationAction.new(
      admin_user: admin,
      target_type: "professional_profile",
      target_id: SecureRandom.uuid,
      action: "hidden",
      request_id: "moderation-audit-invalid",
      created_at: Time.current
    )
    expect(invalid).not_to be_valid
    expect(invalid.errors[:reason]).to be_present

    relationship_action = invalid.dup
    relationship_action.action = "approved"
    relationship_action.reason = nil
    relationship_action.target_type = "professional_profile"
    expect(relationship_action).not_to be_valid
    expect(relationship_action.errors[:action]).to be_present

    approval_with_reason = invalid.dup
    approval_with_reason.target_type = "verification_request"
    approval_with_reason.action = "approved"
    approval_with_reason.reason = "Este motivo não se aplica à aprovação."
    expect(approval_with_reason).not_to be_valid
    expect(approval_with_reason.errors[:reason]).to be_present
  end
end
