# frozen_string_literal: true

require "rails_helper"

RSpec.describe AdminSeed, type: :service do
  before do
    allow(ENV).to receive(:[]).and_call_original
    allow(ENV).to receive(:[]).with("ADMIN_AUTH_EMAIL").and_return(nil)
    allow(ENV).to receive(:[]).with("ADMIN_AUTH_PASSWORD").and_return(nil)
  end

  it "creates the default administrator once and preserves later credential changes" do
    seed = described_class.new

    expect do
      2.times { seed.call }
    end.to change(UserAccount, :count).by(1).and change(AdminAccessEvent, :count).by(1)

    account = UserAccount.find_by!(email: "admin@berufe.com.br")
    expect(account).to be_admin
    expect(account.authenticate("@Qwer1234")).to eq(account)
    expect(AdminAccessEvent.last).to have_attributes(
      admin_user: account,
      action: "provisioned",
      operator_identifier: "database-seed",
      request_id: "admin-seed"
    )

    account.update!(
      password: "a-different-secure-password",
      password_confirmation: "a-different-secure-password"
    )
    seed.call
    expect(account.reload.authenticate("a-different-secure-password")).to eq(account)
    expect(account.authenticate("@Qwer1234")).to be(false)
  end

  it "uses configured non-production credentials" do
    allow(ENV).to receive(:[]).with("ADMIN_AUTH_EMAIL").and_return("configured@example.com")
    allow(ENV).to receive(:[]).with("ADMIN_AUTH_PASSWORD").and_return("configured-password")

    account = described_class.new.call

    expect(account.email).to eq("configured@example.com")
    expect(account.authenticate("configured-password")).to eq(account)
  end

  it "refuses to read credentials or write records in production and logs a warning" do
    allow(Rails).to receive(:env).and_return(ActiveSupport::StringInquirer.new("production"))
    allow(Rails.logger).to receive(:warn)

    expect do
      expect(described_class.new.call).to be_nil
    end.not_to change(UserAccount, :count)

    expect(ENV).not_to have_received(:[]).with("ADMIN_AUTH_EMAIL")
    expect(ENV).not_to have_received(:[]).with("ADMIN_AUTH_PASSWORD")
    expect(Rails.logger).to have_received(:warn).with(
      "Administrator seed skipped in production."
    )
  end
end
