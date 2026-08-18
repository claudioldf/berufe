# frozen_string_literal: true

require "rails_helper"

RSpec.describe PublicWhatsappUrl do
  it "builds only an allowlisted HTTPS redirect with a short encoded pt-BR message" do
    url = described_class.call(
      phone_e164: "+5547999991111",
      service_name: "Instalação elétrica"
    )
    uri = URI.parse(url)

    expect(uri).to have_attributes(scheme: "https", host: "wa.me", path: "/5547999991111")
    expect(URI.decode_www_form(uri.query).to_h.fetch("text")).to eq(
      "Olá! Vi seu perfil na Berufe para Instalação elétrica."
    )
  end

  it "rejects a missing or malformed approved contact instead of redirecting elsewhere" do
    [nil, "5547999991111", "https://evil.example"].each do |phone|
      expect do
        described_class.call(phone_e164: phone, service_name: "Eletricista")
      end.to raise_error(described_class::InvalidContact)
    end
  end
end
