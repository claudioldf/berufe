# frozen_string_literal: true

require "rails_helper"

RSpec.describe ProfessionalCustomerUpdater do
  let(:account) do
    UserAccount.create!(phone_e164: "+5547999982701", role: "professional", status: "active")
  end
  let(:profile) { ProfessionalProfile.create!(user_account: account, display_name: "Ana Clientes") }
  let(:verified_at) { 1.day.ago.change(usec: 0) }
  let(:customer) do
    profile.customers.create!(
      name: "Maria Cliente",
      whatsapp_e164: "+5547999982702",
      email: "maria@example.com",
      email_verified_at: verified_at
    )
  end

  it "normalizes fields and keeps verification when the normalized email is unchanged" do
    result = described_class.new.call(
      customer:,
      attributes: {
        name: "  Maria   da Silva  ",
        whatsapp_e164: "(47) 99998-2702",
        email: " MARIA@EXAMPLE.COM "
      }
    )

    expect(result).to have_attributes(
      name: "Maria da Silva",
      whatsapp_e164: "+5547999982702",
      email: "maria@example.com",
      email_verified_at: verified_at
    )
  end

  it "clears verification only when the normalized email changes" do
    result = described_class.new.call(
      customer:,
      attributes: {
        name: customer.name,
        whatsapp_e164: customer.whatsapp_e164,
        email: "nova@example.com"
      }
    )

    expect(result.email).to eq("nova@example.com")
    expect(result.email_verified_at).to be_nil
  end
end
