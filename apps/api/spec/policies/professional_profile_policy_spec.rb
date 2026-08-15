# frozen_string_literal: true

require "rails_helper"

RSpec.describe ProfessionalProfilePolicy do
  let!(:owner) { create_account(phone: "+5547999997001") }
  let!(:non_owner) { create_account(phone: "+5547999997002") }
  let!(:admin) { create_account(phone: "+5547999997003", role: "admin") }
  let!(:suspended_owner) { create_account(phone: "+5547999997004", status: "suspended") }
  let!(:profile) { ProfessionalProfile.create!(user_account: owner, display_name: "Ana Souza") }
  let!(:other_profile) { ProfessionalProfile.create!(user_account: non_owner, display_name: "Bia Lima") }

  it "allows the active owner to read and update only the owned draft" do
    expect(described_class.new(owner, profile).show?).to be(true)
    expect(described_class.new(owner, profile).update?).to be(true)
    expect(described_class.new(owner, other_profile).show?).to be(false)
    expect(described_class.new(owner, other_profile).update?).to be(false)
    expect(resolve_scope(owner)).to contain_exactly(profile)
  end

  it "allows active admins to inspect but not edit professional-owned records" do
    expect(described_class.new(admin, profile).show?).to be(true)
    expect(described_class.new(admin, profile).update?).to be(false)
    expect(resolve_scope(admin)).to contain_exactly(profile, other_profile)
  end

  it "denies anonymous and suspended users" do
    [nil, suspended_owner].each do |actor|
      expect(described_class.new(actor, profile).show?).to be(false)
      expect(described_class.new(actor, profile).update?).to be(false)
      expect(resolve_scope(actor)).to be_empty
    end
  end

  private

  def create_account(phone:, role: "professional", status: "active")
    UserAccount.create!(phone_e164: phone, role:, status:)
  end

  def resolve_scope(actor)
    described_class::Scope.new(actor, ProfessionalProfile).resolve.to_a
  end
end
