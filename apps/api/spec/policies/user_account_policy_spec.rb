# frozen_string_literal: true

require "rails_helper"

RSpec.describe UserAccountPolicy do
  let!(:owner) { create_account(phone: "+5547999992001") }
  let!(:non_owner) { create_account(phone: "+5547999992002") }
  let!(:admin) { create_account(phone: "+5547999992003", role: "admin") }
  let!(:suspended_admin) { create_account(phone: "+5547999992004", role: "admin", status: "suspended") }
  let!(:suspended_professional) do
    create_account(phone: "+5547999992005", status: "suspended")
  end

  it "allows an active professional to read and update only their own account" do
    expect(described_class.new(owner, owner).show?).to be(true)
    expect(described_class.new(owner, owner).update?).to be(true)
    expect(described_class.new(owner, non_owner).show?).to be(false)
    expect(described_class.new(owner, non_owner).update?).to be(false)
    expect(described_class.new(owner, non_owner).suspend?).to be(false)
    expect(described_class.new(owner, non_owner).revoke_all_sessions?).to be(false)
    expect(described_class.new(owner, owner).complete_registration?).to be(true)
    expect(described_class.new(owner, non_owner).complete_registration?).to be(false)
    expect(resolve_scope(owner)).to contain_exactly(owner)
  end

  it "allows an active admin to inspect accounts and perform account access actions" do
    policy = described_class.new(admin, non_owner)

    expect(policy.show?).to be(true)
    expect(policy.update?).to be(false)
    expect(policy.suspend?).to be(true)
    expect(policy.revoke_all_sessions?).to be(true)
    expect(policy.complete_registration?).to be(false)
    expect(resolve_scope(admin)).to contain_exactly(
      owner,
      non_owner,
      admin,
      suspended_admin,
      suspended_professional
    )
  end

  it "denies anonymous and suspended actors and returns no records" do
    [nil, suspended_admin].each do |actor|
      policy = described_class.new(actor, owner)

      expect(policy.show?).to be(false)
      expect(policy.update?).to be(false)
      expect(policy.suspend?).to be(false)
      expect(policy.revoke_all_sessions?).to be(false)
      expect(policy.complete_registration?).to be(false)
      expect(resolve_scope(actor)).to be_empty
    end

    suspended_policy = described_class.new(suspended_professional, suspended_professional)
    expect(suspended_policy.complete_registration?).to be(false)
  end

  private

  def create_account(phone:, role: "professional", status: "active")
    if role == "admin"
      UserAccount.create!(
        email: "admin-#{phone.delete("+")}@example.com",
        password: "a-secure-admin-password",
        password_confirmation: "a-secure-admin-password",
        role:,
        status:
      )
    else
      UserAccount.create!(phone_e164: phone, role:, status:)
    end
  end

  def resolve_scope(actor)
    described_class::Scope.new(actor, UserAccount).resolve.to_a
  end
end
