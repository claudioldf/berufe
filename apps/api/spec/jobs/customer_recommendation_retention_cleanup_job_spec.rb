# frozen_string_literal: true

require "rails_helper"

RSpec.describe CustomerRecommendationRetentionCleanupJob do
  let(:now) { Time.zone.parse("2026-08-23 16:00:00 UTC") }
  let(:account) { UserAccount.create!(phone_e164: "+5547999998611", role: "professional", status: "active") }
  let(:profile) { ProfessionalProfile.create!(user_account: account, display_name: "Ana Souza") }

  it "expires open invitations and removes completed or expired operational records after thirty days" do
    old_open = create_request(status: "open", expires_at: now - 31.days)
    old_completed = create_request(
      status: "completed",
      expires_at: now - 40.days,
      completed_at: now - 30.days
    )
    recent_expired = create_request(status: "expired", expires_at: now - 29.days)

    described_class.perform_now(now:)

    expect(CustomerRecommendationRequest.exists?(old_open.id)).to be(false)
    expect(CustomerRecommendationRequest.exists?(old_completed.id)).to be(false)
    expect(recent_expired.reload).to be_expired
  end

  private

  def create_request(status:, expires_at:, completed_at: nil)
    quote = ProfessionalQuoteWriter.new.call(
      profile:,
      attributes: {
        customer: {
          id: nil,
          name: "Marina Cliente",
          whatsapp_e164: "+5547999918611",
          email: "marina@example.com"
        },
        service_description: "Serviço #{SecureRandom.hex(4)}",
        valid_until: now.to_date + 7.days,
        discount_amount: 0,
        notes: nil,
        items: [{description: "Serviço", quantity: 1, unit: "hora", unit_price: 100}]
      }
    )
    service_job = ServiceJob.create!(
      quote:,
      status: "completed",
      completed_at: now - 40.days
    )
    token = CustomerRecommendationToken.issue
    service_job.create_customer_recommendation_request!(
      token_hash: CustomerRecommendationToken.digest(token),
      token_ciphertext: CustomerRecommendationToken.encrypt(token),
      delivery_channel: "email",
      email_fingerprint: CustomerEmailFingerprint.call(quote.customer_email),
      status:,
      expires_at:,
      completed_at:
    )
  end
end
