# frozen_string_literal: true

require "rails_helper"

RSpec.describe ProfessionalWelcomeMailer do
  it "welcomes the professional and links to onboarding in HTML and text" do
    mail = described_class.with(
      email: "ana@example.com",
      display_name: "Ana Reparos"
    ).welcome

    expect(mail.to).to eq(["ana@example.com"])
    expect(mail.subject).to eq("Boas-vindas à Berufe")
    expect(mail.html_part.body.decoded).to include(
      "Boas-vindas à Berufe, Ana Reparos!",
      "#{ENV.fetch("WEB_ORIGIN")}/app/professional/onboarding",
      "Completar meu perfil"
    )
    expect(mail.text_part.body.decoded).to include(
      "Boas-vindas à Berufe, Ana Reparos!",
      "#{ENV.fetch("WEB_ORIGIN")}/app/professional/onboarding"
    )
  end
end
