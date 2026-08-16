# frozen_string_literal: true

require "rails_helper"

RSpec.describe AdminAccessEvent, type: :model do
  it "records an append-only administrator credential event" do
    admin = create_admin
    event = described_class.create!(
      admin_user: admin,
      action: "provisioned",
      operator_identifier: "ops@example.com",
      request_id: "manual-provision",
      created_at: Time.current
    )

    expect(event).to be_readonly
    expect { event.update!(action: "password_reset") }.to raise_error(ActiveRecord::ReadOnlyRecord)
    expect { event.destroy! }.to raise_error(ActiveRecord::ReadOnlyRecord)
  end

  it "rejects events for professional accounts" do
    professional = UserAccount.create!(
      phone_e164: "+5547999998111",
      role: "professional",
      status: "active"
    )
    event = described_class.new(
      admin_user: professional,
      action: "provisioned",
      operator_identifier: "ops@example.com",
      created_at: Time.current
    )

    expect(event).not_to be_valid
  end

  private

  def create_admin
    UserAccount.create!(
      email: "admin@example.com",
      password: "a-secure-admin-password",
      password_confirmation: "a-secure-admin-password",
      role: "admin",
      status: "active"
    )
  end
end
