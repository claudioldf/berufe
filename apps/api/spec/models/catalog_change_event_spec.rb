# frozen_string_literal: true

require "rails_helper"

RSpec.describe CatalogChangeEvent, type: :model do
  it "records an append-only catalog mutation attributed to an administrator" do
    admin = create_admin
    event = described_class.create!(
      admin_user: admin,
      catalog_type: "service",
      target_identifier: "eletricista",
      action: "updated",
      change_data: {before: {name: "Eletricista"}, after: {name: "Eletricista residencial"}},
      request_id: "catalog-update",
      created_at: Time.current
    )

    expect(event).to be_readonly
    expect { event.update!(action: "deactivated") }.to raise_error(ActiveRecord::ReadOnlyRecord)
    expect { event.destroy! }.to raise_error(ActiveRecord::ReadOnlyRecord)
  end

  it "rejects unsupported event values and professional actors" do
    professional = UserAccount.create!(
      phone_e164: "+5547999998222",
      role: "professional",
      status: "active"
    )
    event = described_class.new(
      admin_user: professional,
      catalog_type: "category",
      target_identifier: "",
      action: "deleted",
      change_data: [],
      request_id: "invalid event"
    )

    expect(event).not_to be_valid
    expect(event.errors).to include(:admin_user, :catalog_type, :target_identifier, :action, :change_data, :request_id)
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
