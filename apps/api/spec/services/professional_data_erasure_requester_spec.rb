# frozen_string_literal: true

require "rails_helper"

RSpec.describe ProfessionalDataErasureRequester do
  let(:now) { Time.zone.parse("2026-08-23 15:00:00 UTC") }
  let(:account) do
    UserAccount.create!(
      phone_e164: "+5547999998311",
      role: "professional",
      status: "active",
      phone_verified_at: now - 1.hour
    )
  end
  let(:profile) { ProfessionalProfile.create!(user_account: account, display_name: "Ana Souza") }

  it "requires recent SMS control before accepting an irreversible request" do
    profile

    expect do
      described_class.new.call(
        phone_e164: account.phone_e164,
        ticket_reference: "SUP-2026-001",
        now:
      )
    end.to raise_error(described_class::VerificationRequired)

    expect(account.reload).to be_active
    expect(profile.reload.profile_status).to eq("draft")
  end

  it "immediately suspends publication, sessions, quote links, and recommendation invitations" do
    profile
    session, = ApplicationSession.issue!(user_account: account, now: now - 5.minutes)
    quote = create_shared_quote
    old_share_hash = quote.share_token_hash
    service_job = ServiceJob.create!(quote:, status: "completed", completed_at: now - 1.day)
    invitation = service_job.create_customer_recommendation_request!(
      token_hash: CustomerRecommendationToken.digest(CustomerRecommendationToken.issue),
      token_ciphertext: CustomerRecommendationToken.encrypt(CustomerRecommendationToken.issue),
      email_fingerprint: CustomerEmailFingerprint.call(quote.customer_email),
      expires_at: now + 14.days,
      sent_at: now - 1.day
    )

    expect do
      @request_record = described_class.new.call(
        phone_e164: account.phone_e164,
        ticket_reference: "SUP-2026-002",
        now:
      )
    end.to have_enqueued_job(ProfessionalDataErasureJob)

    expect(account.reload.status).to eq("suspended")
    expect(profile.reload.profile_status).to eq("suspended")
    expect(session.reload.revoked_at).to eq(now)
    expect(quote.reload.share_token_hash).not_to eq(old_share_hash)
    expect(invitation.reload).to have_attributes(status: "expired", token_ciphertext: nil)
    expect(@request_record).to have_attributes(
      status: "requested",
      verification_method: "recent_sms_otp",
      unpublished_at: now
    )
  end

  private

  def create_shared_quote
    quote = ProfessionalQuoteWriter.new.call(
      profile:,
      attributes: {
        customer: {
          id: nil,
          name: "Marina Cliente",
          whatsapp_e164: "+5547999918311",
          email: "marina@example.com"
        },
        service_description: "Instalação elétrica",
        valid_until: now.to_date + 7.days,
        discount_amount: 0,
        notes: nil,
        items: [{description: "Instalação", quantity: 1, unit: "serviço", unit_price: 100}]
      }
    )
    token = QuoteShareToken.issue
    quote.update!(
      status: "shared",
      share_token_hash: QuoteShareToken.digest(token),
      share_token_ciphertext: QuoteShareToken.encrypt(token),
      shared_at: now - 1.day
    )
    quote
  end
end
