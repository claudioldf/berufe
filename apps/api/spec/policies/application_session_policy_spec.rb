# frozen_string_literal: true

require "rails_helper"

RSpec.describe ApplicationSessionPolicy do
  let(:owner) { create_account(phone: "+5547999991001") }
  let(:non_owner) { create_account(phone: "+5547999991002") }
  let(:admin) { create_account(phone: "+5547999991003", role: "admin") }
  let(:suspended_owner) { create_account(phone: "+5547999991004", status: "suspended") }
  let(:owner_session) { ApplicationSession.issue!(user_account: owner).first }

  it "allows only the active owner to inspect or end an owned session" do
    expect(described_class.new(owner, owner_session).show?).to be(true)
    expect(described_class.new(owner, owner_session).destroy?).to be(true)

    [nil, non_owner, admin, suspended_owner].each do |actor|
      expect(described_class.new(actor, owner_session).show?).to be(false)
      expect(described_class.new(actor, owner_session).destroy?).to be(false)
    end
  end

  it "scopes sessions to the active owner without granting administrators blanket access" do
    owned_session = owner_session
    non_owner_session = ApplicationSession.issue!(user_account: non_owner).first
    now = Time.current
    admin_session = ApplicationSession.issue!(user_account: admin, now:).first

    expect(resolve_scope(owner)).to contain_exactly(owned_session)
    expect(resolve_scope(non_owner)).to contain_exactly(non_owner_session)
    expect(resolve_scope(admin)).to contain_exactly(admin_session)
    expect(resolve_scope(suspended_owner)).to be_empty
    expect(resolve_scope(nil)).to be_empty
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
    described_class::Scope.new(actor, ApplicationSession).resolve.to_a
  end
end
