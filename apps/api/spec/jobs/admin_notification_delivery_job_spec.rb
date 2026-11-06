# frozen_string_literal: true

require "rails_helper"

RSpec.describe AdminNotificationDeliveryJob do
  before { ActionMailer::Base.deliveries.clear }

  let(:admin) do
    UserAccount.create!(
      role: "admin", status: "active", email: "admin@example.com", email_verified_at: Time.current,
      password: "Str0ng!Passw0rd#1", password_confirmation: "Str0ng!Passw0rd#1"
    )
  end
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
    described_class.perform_now("professional_registered", account.id, admin.id)

    mail = ActionMailer::Base.deliveries.sole
    expect(mail.to).to eq([admin.email])
    expect(mail.message_id).to eq("admin-professional-registered-#{account.id}-#{admin.id}@berufe.com.br")
    body = mail.html_part.body.decoded + mail.text_part.body.decoded
    expect(body).to include("Ana Reparos")
    expect(body).not_to include("ana@example.com", "+5547999997001")
  end

  it "delivers a verification notice" do
    request = profile.verification_requests.create!(
      verification_type: "identity", status: "pending_review", submitted_at: Time.current
    )

    described_class.perform_now("verification_submitted", request.id, admin.id)

    expect(ActionMailer::Base.deliveries.sole.subject).to eq("Nova identidade aguardando análise")
  end

  it "skips suspended administrators, missing subjects, and incomplete registrations" do
    admin.update_columns(status: "suspended")
    described_class.perform_now("professional_registered", account.id, admin.id)
    admin.update_columns(status: "active")
    described_class.perform_now("verification_submitted", SecureRandom.uuid, admin.id)
    account.update_columns(registered_at: nil)
    described_class.perform_now("professional_registered", account.id, admin.id)

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
      described_class.new.perform("professional_registered", account.id, admin.id, mailer:)
    end.to raise_error(Berufe::MailDelivery::ProviderUnavailable)
  end
end
