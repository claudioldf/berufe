# frozen_string_literal: true

require "rails_helper"

RSpec.describe ProfessionalRelationship do
  let(:initiator) { create_profile("+5547999997001", "Ana Iniciadora") }
  let(:recipient) { create_profile("+5547999997002", "Beto Destinatário") }

  it "normalizes a valid pending relationship and prevents directional duplicates" do
    relationship = described_class.create!(
      initiator_professional: initiator,
      recipient_professional: recipient,
      relationship_type: "recommendation",
      context_note: "  Trabalhamos juntos em uma reforma.  "
    )

    expect(relationship.context_note).to eq("Trabalhamos juntos em uma reforma.")
    duplicate = described_class.new(
      initiator_professional: initiator,
      recipient_professional: recipient,
      relationship_type: "recommendation"
    )
    expect(duplicate).not_to be_valid
    expect(duplicate.errors[:relationship_type]).to be_present

    relationship.update!(deleted_at: Time.current)
    replacement = described_class.new(
      initiator_professional: initiator,
      recipient_professional: recipient,
      relationship_type: "recommendation"
    )
    expect(replacement).to be_valid
  end

  it "rejects self relationships and inconsistent response state" do
    self_relationship = described_class.new(
      initiator_professional: initiator,
      recipient_professional: initiator,
      relationship_type: "worked_together"
    )
    expect(self_relationship).not_to be_valid
    expect(self_relationship.errors[:recipient_professional]).to be_present

    pending_with_response = described_class.new(
      initiator_professional: initiator,
      recipient_professional: recipient,
      relationship_type: "worked_together",
      responded_at: Time.current
    )
    expect(pending_with_response).not_to be_valid
    expect(pending_with_response.errors[:responded_at]).to be_present

    accepted_without_response = described_class.new(
      initiator_professional: initiator,
      recipient_professional: recipient,
      relationship_type: "worked_together",
      status: "accepted"
    )
    expect(accepted_without_response).not_to be_valid
    expect(accepted_without_response.errors[:responded_at]).to be_present
  end

  private

  def create_profile(phone, name)
    account = UserAccount.create!(phone_e164: phone, role: "professional", status: "active")
    ProfessionalProfile.create!(user_account: account, display_name: name)
  end
end
