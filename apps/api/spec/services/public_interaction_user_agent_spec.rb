# frozen_string_literal: true

require "rails_helper"

RSpec.describe PublicInteractionUserAgent do
  it "counts ordinary browsers and excludes obvious bots, previews, and scripted clients" do
    expect(described_class.countable?(
      "Mozilla/5.0 (Linux; Android 16) AppleWebKit/537.36 Chrome/140 Mobile Safari/537.36"
    )).to be(true)
    expect(described_class.countable?(nil)).to be(true)

    [
      "facebookexternalhit/1.1",
      "Slackbot-LinkExpanding 1.0",
      "WhatsApp/2.26",
      "Googlebot/2.1",
      "Mozilla/5.0 HeadlessChrome/140",
      "curl/8.7.1"
    ].each do |user_agent|
      expect(described_class.countable?(user_agent)).to be(false)
    end
  end
end
