# frozen_string_literal: true

require "rails_helper"

RSpec.describe AdminNotificationMailer do
  let(:web_origin) { ENV.fetch("WEB_ORIGIN").delete_suffix("/") }
  let(:moment) { Time.utc(2026, 11, 6, 15, 30) }

  def assert_centered_cta(html)
    cta = Nokogiri::HTML.fragment(html).at_css("a.email-button")
    expect(cta.parent["align"]).to eq("center")
    expect(cta.ancestors("table").first["align"]).to eq("center")
  end

  it "announces a new professional registration" do
    mail = described_class.with(
      email: "admin@example.com", professional_id: "acc-1", request_id: "req-1", display_name: "Ana Reparos", registered_at: moment, claimed: false
    ).professional_registered

    expect(mail.to).to eq(["admin@example.com"])
    expect(mail.subject).to eq("Novo cadastro profissional na Berufe")
    html = mail.html_part.body.decoded
    text = mail.text_part.body.decoded
    expect(html).to include("Ana Reparos", "Perfil criado", "06/11/2026 às 12:30",
      "#{web_origin}/app/admin/professionals?id=acc-1", "Abrir este profissional")
    expect(text).to include("Ana Reparos", "Perfil criado", "#{web_origin}/app/admin/professionals?id=acc-1")
    assert_centered_cta(html)
  end

  it "labels claimed profiles" do
    mail = described_class.with(
      email: "admin@example.com", professional_id: "acc-1", request_id: "req-1", display_name: "Ana", registered_at: moment, claimed: true
    ).professional_registered

    expect(mail.html_part.body.decoded).to include("Perfil reivindicado")
  end

  it "announces identity evidence awaiting review" do
    mail = described_class.with(
      email: "admin@example.com", professional_id: "acc-1", request_id: "req-1", display_name: "Ana Reparos", submitted_at: moment
    ).verification_submitted

    expect(mail.subject).to eq("Nova identidade aguardando análise")
    html = mail.html_part.body.decoded
    text = mail.text_part.body.decoded
    expect(html).to include("Ana Reparos", "Documento de identidade enviado", "Analisar esta identidade",
      "#{web_origin}/app/admin?busca=req-1&amp;status=all")
    expect(text).to include("Documento de identidade enviado", "#{web_origin}/app/admin?busca=req-1&status=all")
    assert_centered_cta(html)
  end
end
