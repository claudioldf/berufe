# frozen_string_literal: true

require "rails_helper"

RSpec.describe AdminProfessionalPolicy do
  it "allows only an active administrator to manage the professional directory" do
    active_admin = create_account(role: "admin", status: "active", sequence: 1)
    suspended_admin = create_account(role: "admin", status: "suspended", sequence: 2)
    professional = create_account(role: "professional", status: "active", sequence: 3)

    expect(described_class.new(active_admin, :admin_professional).manage?).to be(true)
    expect(described_class.new(suspended_admin, :admin_professional).manage?).to be(false)
    expect(described_class.new(professional, :admin_professional).manage?).to be(false)
    expect(described_class.new(nil, :admin_professional).manage?).to be(false)
  end

  private

  def create_account(role:, status:, sequence:)
    if role == "admin"
      UserAccount.create!(
        email: "admin-professional-#{sequence}@example.com",
        password: "a-secure-admin-password",
        password_confirmation: "a-secure-admin-password",
        role:,
        status:
      )
    else
      UserAccount.create!(phone_e164: "+5547999997#{sequence.to_s.rjust(3, "0")}", role:, status:)
    end
  end
end
