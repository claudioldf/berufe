# frozen_string_literal: true

require "rails_helper"

RSpec.describe AdminCatalogPolicy do
  it "allows only an active administrator to manage the private catalog" do
    active_admin = create_account(role: "admin", status: "active", sequence: 1)
    suspended_admin = create_account(role: "admin", status: "suspended", sequence: 2)
    professional = create_account(role: "professional", status: "active", sequence: 3)

    expect(described_class.new(active_admin, :admin_catalog).manage?).to be(true)
    expect(described_class.new(suspended_admin, :admin_catalog).manage?).to be(false)
    expect(described_class.new(professional, :admin_catalog).manage?).to be(false)
    expect(described_class.new(nil, :admin_catalog).manage?).to be(false)
  end

  private

  def create_account(role:, status:, sequence:)
    if role == "admin"
      UserAccount.create!(
        email: "admin-#{sequence}@example.com",
        password: "a-secure-admin-password",
        password_confirmation: "a-secure-admin-password",
        role:,
        status:
      )
    else
      UserAccount.create!(phone_e164: "+5547999998#{sequence.to_s.rjust(3, "0")}", role:, status:)
    end
  end
end
