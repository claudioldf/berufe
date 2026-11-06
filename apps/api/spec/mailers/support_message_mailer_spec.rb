# frozen_string_literal: true

require "rails_helper"

RSpec.describe SupportMessageMailer do
  let(:params) do
    {
      recipient: "ops@example.com", name: "Ana Souza", email: "ana@example.com",
      phone: "+5547999997701", message: "Ola <script>alert(1)</script>", topic: "excluir-conta"
    }
  end

  it "addresses the administrator with the sender as Reply-To" do
    mail = described_class.with(**params).received

    expect(mail.to).to eq(["ops@example.com"])
    expect(mail.reply_to).to eq(["ana@example.com"])
    expect(mail.subject).to eq("Contato de suporte — Excluir conta")
    expect(mail.text_part.body.decoded).to include("Ana Souza", "+5547999997701")
  end

  it "escapes the visitor message in the HTML body" do
    html = described_class.with(**params).received.html_part.body.decoded

    expect(html).not_to include("<script>")
    expect(html).to include("&lt;script&gt;")
  end

  it "falls back to the general label for an unknown topic" do
    mail = described_class.with(**params, topic: "outro").received

    expect(mail.subject).to eq("Contato de suporte — Geral")
  end
end
