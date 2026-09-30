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
    html = mail.html_part.body.decoded
    text = mail.text_part.body.decoded
    expect(html).to include(
      "Boas-vindas à Berufe, Ana Reparos!",
      "#{ENV.fetch("WEB_ORIGIN")}/app/professional/onboarding",
      "#{ENV.fetch("WEB_ORIGIN")}/images/email/welcome-features-diorama.jpg",
      "Profissional mostrando seu portfólio, sua confiança e o contato direto com clientes",
      "Seu trabalho merece ser visto.",
      "Mostre seu trabalho",
      "Construa confiança",
      "Receba contatos diretos",
      "Completar meu perfil"
    )
    expect(text).to include(
      "Boas-vindas à Berufe, Ana Reparos!",
      "Seu trabalho merece ser visto.",
      "Mostre seu trabalho",
      "Construa confiança",
      "Receba contatos diretos",
      "#{ENV.fetch("WEB_ORIGIN")}/app/professional/onboarding"
    )

    cta = Nokogiri::HTML.fragment(html).at_css("a.email-button")
    expect(cta.parent["align"]).to eq("center")
    expect(cta.ancestors("table").first["align"]).to eq("center")
  end
end
