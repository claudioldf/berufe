# frozen_string_literal: true

require "rails_helper"

RSpec.describe QuotePolicy do
  let(:owner) { create_account("+5547999997421") }
  let(:other) { create_account("+5547999997422") }
  let(:profile) { ProfessionalProfile.create!(user_account: owner, display_name: "Ana Souza") }
  let(:quote) { profile.quotes.new }

  it "allows only the active owner to create and edit while retaining operational admin reads" do
    owner_policy = described_class.new(owner, quote)
    expect(owner_policy.create?).to be(true)
    expect(owner_policy.update?).to be(true)
    expect(owner_policy.share?).to be(true)
    expect(owner_policy.show?).to be(true)
    other_policy = described_class.new(other, quote)
    expect(other_policy.create?).to be(false)
    expect(other_policy.update?).to be(false)
    expect(other_policy.share?).to be(false)
    expect(other_policy.show?).to be(false)

    admin = UserAccount.create!(
      email: "quote-policy@example.com",
      password: "a-secure-admin-password",
      password_confirmation: "a-secure-admin-password",
      role: "admin",
      status: "active"
    )
    admin_policy = described_class.new(admin, quote)
    expect(admin_policy.show?).to be(true)
    expect(admin_policy.create?).to be(false)
    expect(admin_policy.update?).to be(false)
    expect(admin_policy.share?).to be(false)

    owner.update!(status: "suspended")
    suspended_policy = described_class.new(owner, quote)
    expect(suspended_policy.create?).to be(false)
    expect(suspended_policy.update?).to be(false)
    expect(suspended_policy.share?).to be(false)
    expect(suspended_policy.show?).to be(false)
  end

  it "scopes professionals to owned quotes and administrators to operational reads" do
    persisted = ProfessionalQuoteWriter.new.call(
      profile:,
      attributes: {
        customer_name: "Cliente",
        service_description: "Serviço",
        discount_amount: 0,
        items: [{description: "Item", quantity: 1, unit: "serviço", unit_price: 10}]
      }
    )
    other_profile = ProfessionalProfile.create!(user_account: other, display_name: "Beto Lima")
    ProfessionalQuoteWriter.new.call(
      profile: other_profile,
      attributes: {
        customer_name: "Outro cliente",
        service_description: "Outro serviço",
        discount_amount: 0,
        items: [{description: "Item", quantity: 1, unit: "serviço", unit_price: 10}]
      }
    )
    admin = UserAccount.create!(
      email: "quote-scope@example.com",
      password: "a-secure-admin-password",
      password_confirmation: "a-secure-admin-password",
      role: "admin",
      status: "active"
    )

    expect(described_class::Scope.new(owner, Quote).resolve).to contain_exactly(persisted)
    expect(described_class::Scope.new(admin, Quote).resolve.count).to eq(2)
  end

  private

  def create_account(phone)
    UserAccount.create!(phone_e164: phone, role: "professional", status: "active")
  end
end
