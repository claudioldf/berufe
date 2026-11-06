# frozen_string_literal: true

require "rails_helper"

RSpec.describe ProfessionalIdentityApprovedSmsJob do
  let(:account) { UserAccount.create!(role: "professional", status: "active", phone_e164: "+5547999998303") }
  let!(:profile) { ProfessionalProfile.create!(user_account: account, display_name: "Ana Reparos") }
  let(:request) do
    profile.verification_requests.create!(verification_type: "identity", status: "approved", submitted_at: Time.current)
  end
  let(:client) { instance_double(FakeSmsOtpClient, send_text: nil) }

  it "texts the public profile link to the professional's phone" do
    described_class.perform_now(request.id, client:)

    link = "#{ENV.fetch("WEB_ORIGIN").delete_suffix("/")}/be/#{profile.public_slug}"
    expect(client).to have_received(:send_text).with(
      phone: "+5547999998303",
      text: a_string_including("Berufe", "identidade", link)
    )
  end

  it "keeps the text in a single GSM segment" do
    profile.update_columns(public_slug: "a" * 60)

    described_class.perform_now(request.id, client:)

    expect(client).to have_received(:send_text) do |text:, **|
      expect(text).to be_ascii_only
      expect(text.length).to be <= 160
    end
  end

  it "does not text unapproved requests" do
    request.update!(status: "pending_review")

    described_class.perform_now(request.id, client:)

    expect(client).not_to have_received(:send_text)
  end

  it "reports and re-raises provider failures so the job retries" do
    allow(client).to receive(:send_text).and_raise(SmsOtp::ProviderUnavailable)
    expect(Rails.error).to receive(:report).with(instance_of(SmsOtp::ProviderUnavailable), anything)

    expect { described_class.new.perform(request.id, client:) }.to raise_error(SmsOtp::ProviderUnavailable)
  end
end
