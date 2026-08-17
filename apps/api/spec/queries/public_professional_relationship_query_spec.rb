# frozen_string_literal: true

require "rails_helper"

RSpec.describe PublicProfessionalRelationshipQuery do
  let(:admin) do
    UserAccount.create!(
      email: "relationship-reviewer@berufe.com.br",
      password: "@Qwer1234",
      role: "admin",
      status: "active"
    )
  end
  let(:initiator) { create_published_profile("+5547999997101", "Ana Pública") }
  let(:recipient) { create_published_profile("+5547999997102", "Beto Público") }

  it "returns accepted relationships whose latest moderation action is public for both endpoints" do
    relationship = create_relationship
    moderate(relationship, "approved", at: 2.minutes.ago)

    expect(described_class.for_professional(initiator.id)).to contain_exactly(relationship)
    expect(described_class.for_professional(recipient.id)).to contain_exactly(relationship)

    moderate(relationship, "hidden", at: 1.minute.ago, reason: "Conteúdo ocultado para revisão operacional.")
    expect(described_class.for_professional(initiator.id)).to be_empty

    moderate(relationship, "restored", at: Time.current)
    expect(described_class.for_professional(initiator.id)).to contain_exactly(relationship)
  end

  it "excludes unreviewed, pending, and relationships with a non-public endpoint" do
    accepted = create_relationship
    expect(described_class.call).to be_empty

    moderate(accepted, "approved", at: Time.current)
    recipient.user_account.update!(status: "suspended")
    expect(described_class.call).to be_empty

    accepted.update!(status: "declined")
    expect(described_class.call).to be_empty
  end

  private

  def create_published_profile(phone, name)
    account = UserAccount.create!(phone_e164: phone, role: "professional", status: "active")
    profile = ProfessionalProfile.create!(user_account: account, display_name: name)
    revision = profile.working_revision
    revision.update!(status: "approved", reviewed_at: Time.current)
    profile.update!(profile_status: "published", published_revision: revision)
    profile
  end

  def create_relationship
    ProfessionalRelationship.create!(
      initiator_professional: initiator,
      recipient_professional: recipient,
      relationship_type: "worked_together",
      status: "accepted",
      responded_at: 3.minutes.ago
    )
  end

  def moderate(relationship, action, at:, reason: nil)
    ModerationAction.create!(
      admin_user: admin,
      target_type: "professional_relationship",
      target_id: relationship.id,
      action:,
      reason:,
      request_id: "relationship-#{action}-#{SecureRandom.hex(4)}",
      created_at: at
    )
  end
end
