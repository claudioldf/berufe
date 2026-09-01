# frozen_string_literal: true

require "rails_helper"

module CustomerRecommendationRequestDeliveryJobSpecSupport
  # Stands in for CustomerRecommendationMailer: `.with(...).invitation` chain
  # returning an object that responds to the two calls the job makes
  # (`message_id=`, `deliver_now`), so the mail-delivery failure paths can be
  # exercised without a real ActionMailer delivery method or network access.
  #
  # A named (not anonymous) class, because retry_on re-enqueues the job with
  # its original arguments — including the injected `mailer:` — and
  # ActiveJob can only serialize a Class argument that has a real name.
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

    def self.invitation
      delivery
    end
  end
end

RSpec.describe CustomerRecommendationRequestDeliveryJob do
  let(:account) { UserAccount.create!(phone_e164: "+5547999917611", role: "professional", status: "active") }
  let(:profile) { ProfessionalProfile.create!(user_account: account, display_name: "Ana Souza") }

  def create_request(email: "marina@example.com")
    quote = ProfessionalQuoteWriter.new.call(
      profile:,
      attributes: {
        customer: {id: nil, name: "Marina Cliente", whatsapp_e164: "+5547999912611", email:},
        service_description: "Instalação de luminárias",
        valid_until: Date.current + 7.days,
        discount_amount: 0,
        notes: nil,
        items: [{description: "Instalação", quantity: 1, unit: "hora", unit_price: 100}]
      }
    )
    service_job = ServiceJob.create!(quote:, status: "completed", completed_at: Time.current)
    token = CustomerRecommendationToken.issue
    service_job.create_customer_recommendation_request!(
      token_hash: CustomerRecommendationToken.digest(token),
      token_ciphertext: CustomerRecommendationToken.encrypt(token),
      delivery_channel: "email",
      email_fingerprint: CustomerEmailFingerprint.call(quote.customer_email),
      expires_at: 14.days.from_now
    )
  end

  def fake_mailer(error:)
    mailer = CustomerRecommendationRequestDeliveryJobSpecSupport::FakeMailer
    mailer.delivery = CustomerRecommendationRequestDeliveryJobSpecSupport::FakeDelivery.new(error:)
    mailer
  end

  it "delivers the invitation, pins a request-scoped Message-ID, and records the send outside the row lock" do
    request_record = create_request

    described_class.perform_now(request_record.id)

    expect(ActionMailer::Base.deliveries.one?).to be(true)
    delivered = ActionMailer::Base.deliveries.first
    expect(delivered.message_id).to eq("customer-recommendation-#{request_record.id}@berufe.com.br")
    expect(request_record.reload).to have_attributes(token_ciphertext: nil)
    expect(request_record.sent_at).to be_present
  end

  it "is idempotent when a duplicate job runs after the invitation was sent" do
    request_record = create_request

    described_class.perform_now(request_record.id)
    described_class.perform_now(request_record.id)

    expect(ActionMailer::Base.deliveries.one?).to be(true)
  end

  it "does not send anything for a WhatsApp-channel request" do
    request_record = create_request
    request_record.update!(delivery_channel: "whatsapp", email_fingerprint: nil)

    described_class.perform_now(request_record.id)

    expect(ActionMailer::Base.deliveries).to be_empty
  end

  it "does not send anything for an already-expired request" do
    request_record = create_request
    request_record.update!(expires_at: 1.minute.ago)

    described_class.perform_now(request_record.id)

    expect(ActionMailer::Base.deliveries).to be_empty
  end

  it "retries a transient provider failure without clearing the token or reporting delivery as sent" do
    request_record = create_request
    allow(Rails.error).to receive(:report)
    error = Berufe::MailDelivery::ProviderUnavailable.new("Resend is unavailable")

    expect do
      described_class.perform_now(request_record.id, mailer: fake_mailer(error:))
    end.to have_enqueued_job(described_class)

    expect(Rails.error).to have_received(:report).with(
      error,
      context: {customer_recommendation_request_id: request_record.id}
    )
    expect(request_record.reload).to have_attributes(sent_at: nil, token_ciphertext: be_present)
  end

  it "discards a permanently rejected delivery instead of retrying it" do
    request_record = create_request
    allow(Rails.error).to receive(:report)
    error = Berufe::MailDelivery::Rejected.new("Resend rejected the request")

    expect do
      described_class.perform_now(request_record.id, mailer: fake_mailer(error:))
    end.not_to have_enqueued_job(described_class)

    expect(Rails.error).to have_received(:report).with(
      error,
      context: {customer_recommendation_request_id: request_record.id}
    )
    expect(request_record.reload).to have_attributes(sent_at: nil, token_ciphertext: be_present)
  end
end
