# frozen_string_literal: true

require "rails_helper"

RSpec.describe UserAccount, type: :model do
  it "uses a Rails UUID and a unique verified phone as the stable identity" do
    account = described_class.create!(
      phone_e164: "+5547999991111",
      role: "professional",
      status: "active"
    )

    expect(account.id).to match(/\A[0-9a-f-]{36}\z/)
    expect(account).not_to be_admin
    expect do
      described_class.create!(phone_e164: account.phone_e164, role: "professional", status: "active")
    end.to raise_error(ActiveRecord::RecordInvalid)
  end

  it "recognizes deliberately provisioned admin accounts" do
    account = described_class.new(
      phone_e164: "+5547999992222",
      role: "admin",
      status: "active"
    )

    expect(account).to be_admin
  end
end
