# frozen_string_literal: true

require "rails_helper"

RSpec.describe AdminNotificationDeliveryJob do
  before { ActionMailer::Base.deliveries.clear }

  let(:recipient) { "ops@example.com" }
  let(:account) do
    UserAccount.create!(
      role: "professional", status: "active", phone_e164: "+5547999997001", phone_verified_at: Time.current,
      email: "ana@example.com", registered_at: Time.current, terms_accepted_at: Time.current,
      terms_version: LegalDocumentVersions::TERMS,
      privacy_notice_version: LegalDocumentVersions::PRIVACY_NOTICE
    )
  end
  let!(:profile) { ProfessionalProfile.create!(user_account: account, display_name: "Ana Reparos") }

  it "delivers a registration notice with a pinned Message-ID and no professional contact data" do
    described_class.perform_now("professional_registered", account.id, recipient)

    mail = ActionMailer::Base.deliveries.sole
    expect(mail.to).to eq([recipient])
    expect(mail.message_id).to match(/\Aadmin-professional-registered-#{account.id}-\h{12}@berufe\.com\.br\z/)
    body = mail.html_part.body.decoded + mail.text_part.body.decoded
    expect(body).to include("Ana Reparos")
    expect(body).not_to include("ana@example.com", "+5547999997001")
  end

  it "delivers a verification notice" do
    request = profile.verification_requests.create!(
      verification_type: "identity", status: "pending_review", submitted_at: Time.current
    )

    described_class.perform_now("verification_submitted", request.id, recipient)

    expect(ActionMailer::Base.deliveries.sole.subject).to eq("Nova identidade aguardando análise")
  end

  it "skips missing subjects and incomplete registrations" do
    described_class.perform_now("verification_submitted", SecureRandom.uuid, recipient)
    account.update_columns(registered_at: nil)
    described_class.perform_now("professional_registered", account.id, recipient)

    expect(ActionMailer::Base.deliveries).to be_empty
  end

  it "reports and re-raises provider errors so only this recipient retries" do
    delivery = Class.new do
      attr_writer :message_id

      def deliver_now = raise(Berufe::MailDelivery::ProviderUnavailable)
    end.new
    mailer = Class.new do
      define_singleton_method(:with) { |**| self }
      define_singleton_method(:professional_registered) { delivery }
    end

    expect(Rails.error).to receive(:report).with(instance_of(Berufe::MailDelivery::ProviderUnavailable), anything)
    expect do
      described_class.new.perform("professional_registered", account.id, recipient, mailer:)
    end.to raise_error(Berufe::MailDelivery::ProviderUnavailable)
  end
end
