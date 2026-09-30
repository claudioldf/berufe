# frozen_string_literal: true

require "rails_helper"

module ProfessionalWelcomeEmailDeliveryJobSpecSupport
  class FakeDelivery
    attr_reader :message_id

    def initialize(error: nil)
      @error = error
    end

    attr_writer :message_id

    def deliver_now
      raise @error if @error
    end
  end

  class FakeMailer
    class << self
      attr_accessor :delivery
    end

    def self.with(**)
      self
    end

    def self.welcome
      delivery
    end
  end
end

RSpec.describe ProfessionalWelcomeEmailDeliveryJob do
  before { ActionMailer::Base.deliveries.clear }

  it "delivers one welcome message, pins its Message-ID, and records the send" do
    account = create_registered_account

    described_class.perform_now(account.id)

    expect(ActionMailer::Base.deliveries.one?).to be(true)
    delivered = ActionMailer::Base.deliveries.first
    expect(delivered.to).to eq([account.email])
    expect(delivered.subject).to eq("Boas-vindas à Berufe")
    expect(delivered.message_id).to eq("professional-welcome-#{account.id}@berufe.com.br")
    expect(account.reload.welcome_email_sent_at).to be_present
  end

  it "is idempotent when the delivery job runs more than once" do
    account = create_registered_account

    described_class.perform_now(account.id)
    described_class.perform_now(account.id)

    expect(ActionMailer::Base.deliveries.one?).to be(true)
  end

  it "does not send before registration is complete or without an email" do
    incomplete = UserAccount.create!(
      phone_e164: "+5547999996032",
      email: "incomplete@example.com",
      phone_verified_at: Time.current,
      role: "professional",
      status: "active"
    )
    legacy_without_email = create_registered_account(phone: "+5547999996033", email: nil)

    described_class.perform_now(incomplete.id)
    described_class.perform_now(legacy_without_email.id)

    expect(ActionMailer::Base.deliveries).to be_empty
    expect(incomplete.reload.welcome_email_sent_at).to be_nil
    expect(legacy_without_email.reload.welcome_email_sent_at).to be_nil
  end

  it "retries a transient provider failure without recording the email as sent" do
    account = create_registered_account
    allow(Rails.error).to receive(:report)
    error = Berufe::MailDelivery::ProviderUnavailable.new("Resend is unavailable")

    expect do
      described_class.perform_now(account.id, mailer: fake_mailer(error:))
    end.to have_enqueued_job(described_class)

    expect(Rails.error).to have_received(:report).with(
      error,
      context: {user_account_id: account.id}
    )
    expect(account.reload.welcome_email_sent_at).to be_nil
  end

  it "discards a permanently rejected delivery" do
    account = create_registered_account
    allow(Rails.error).to receive(:report)
    error = Berufe::MailDelivery::Rejected.new("Resend rejected the request")

    expect do
      described_class.perform_now(account.id, mailer: fake_mailer(error:))
    end.not_to have_enqueued_job(described_class)

    expect(Rails.error).to have_received(:report).with(
      error,
      context: {user_account_id: account.id}
    )
    expect(account.reload.welcome_email_sent_at).to be_nil
  end

  private

  def create_registered_account(phone: "+5547999996031", email: "welcome@example.com")
    account = UserAccount.create!(
      phone_e164: phone,
      email:,
      phone_verified_at: Time.current,
      registered_at: Time.current,
      terms_accepted_at: Time.current,
      terms_version: LegalDocumentVersions::TERMS,
      privacy_notice_version: LegalDocumentVersions::PRIVACY_NOTICE,
      role: "professional",
      status: "active"
    )
    ProfessionalProfile.create!(user_account: account, display_name: "Ana Reparos")
    account.reload
  end

  def fake_mailer(error:)
    mailer = ProfessionalWelcomeEmailDeliveryJobSpecSupport::FakeMailer
    mailer.delivery = ProfessionalWelcomeEmailDeliveryJobSpecSupport::FakeDelivery.new(error:)
    mailer
  end
end
