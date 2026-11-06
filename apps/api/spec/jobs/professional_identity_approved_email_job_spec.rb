# frozen_string_literal: true

require "rails_helper"

RSpec.describe ProfessionalIdentityApprovedEmailJob do
  before { ActionMailer::Base.deliveries.clear }

  let(:account) { UserAccount.create!(role: "professional", status: "active", email: "ana@example.com", phone_e164: "+5547999998302") }
  let!(:profile) { ProfessionalProfile.create!(user_account: account, display_name: "Ana Reparos") }
  let(:request) do
    profile.verification_requests.create!(verification_type: "identity", status: "approved", submitted_at: Time.current)
  end

  it "e-mails the public profile link with a pinned Message-ID" do
    described_class.perform_now(request.id)

    mail = ActionMailer::Base.deliveries.sole
    expect(mail.to).to eq(["ana@example.com"])
    expect(mail.subject).to eq("Sua identidade foi verificada na Berufe")
    expect(mail.message_id).to eq("professional-identity-approved-#{request.id}@berufe.com.br")
    link = "#{ENV.fetch("WEB_ORIGIN").delete_suffix("/")}/be/#{profile.public_slug}"
    expect(mail.html_part.body.decoded).to include(
      link, "Ana Reparos", "Ver meu perfil público", "Selo no seu perfil", "Destaque seu trabalho",
      "Receba contatos diretos", "#{ENV.fetch("WEB_ORIGIN")}/images/email/welcome-features-profile-collage.jpg"
    )
    expect(mail.text_part.body.decoded).to include(link)
    cta = Nokogiri::HTML.fragment(mail.html_part.body.decoded).at_css("a.email-button")
    expect(cta.parent["align"]).to eq("center")
  end

  it "skips requests that are not approved and accounts without an e-mail" do
    request.update!(status: "rejected")
    described_class.perform_now(request.id)
    request.update!(status: "approved")
    account.update_columns(email: nil)
    described_class.perform_now(request.id)

    expect(ActionMailer::Base.deliveries).to be_empty
  end
end
