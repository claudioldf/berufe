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

  it "keeps moderation decisions immutable and requires a private reason where needed" do
    action = ModerationAction.create!(
      admin_user: admin,
      target_type: "profile_revision",
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
      target_type: "profile_revision",
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
    relationship_action.target_type = "professional_relationship"
    expect(relationship_action).not_to be_valid
    expect(relationship_action.errors[:target_type]).to be_present
  end

  it "keeps private-media access events immutable and administrator-owned" do
    event = ModerationMediaAccessEvent.create!(
      admin_user: admin,
      target_type: "profile_photo",
      target_id: SecureRandom.uuid,
      request_id: "moderation-media-audit",
      created_at: Time.current
    )

    expect { event.update!(request_id: "changed") }.to raise_error(ActiveRecord::ReadOnlyRecord)
    expect { event.destroy! }.to raise_error(ActiveRecord::ReadOnlyRecord)

    professional = UserAccount.create!(phone_e164: "+5547999998201", role: "professional", status: "active")
    invalid = event.dup
    invalid.admin_user = professional
    expect(invalid).not_to be_valid
    expect(invalid.errors[:admin_user]).to be_present
  end
end
