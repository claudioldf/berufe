# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Phone OTP configuration" do
  it "uses the approved cooldown, daily allowances, and short challenge lifetime" do
    settings = Rails.configuration.x.berufe.otp

    expect(settings.resend_cooldown_seconds).to eq(30)
    expect(settings.daily_phone_limit).to eq(5)
    expect(settings.daily_ip_limit).to eq(20)
    expect(settings.challenge_ttl_seconds).to eq(600)
  end
end
