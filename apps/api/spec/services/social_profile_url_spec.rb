# frozen_string_literal: true

require "rails_helper"

RSpec.describe SocialProfileUrl do
  it "canonicalizes supported Instagram handles and profile URLs" do
    expect(described_class.normalize(" @ana.obras ", platform: :instagram))
      .to eq("https://www.instagram.com/ana.obras/")
    expect(described_class.normalize("http://m.instagram.com/ana.obras/?utm_source=x#bio", platform: :instagram))
      .to eq("https://www.instagram.com/ana.obras/")
    expect(described_class.normalize("", platform: :instagram)).to be_nil
  end

  it "canonicalizes supported YouTube handles and profile URLs" do
    expect(described_class.normalize("Canal-Obras", platform: :youtube))
      .to eq("https://www.youtube.com/@Canal-Obras")
    expect(described_class.normalize("youtube.com/@Canal-Obras?view_as=subscriber", platform: :youtube))
      .to eq("https://www.youtube.com/@Canal-Obras")
  end

  it "rejects off-platform and content URLs" do
    invalid_values = [
      ["https://example.com/ana", :instagram],
      ["instagram.com/reel/abc", :instagram],
      ["youtube.com/watch?v=abc", :youtube],
      ["youtube.com/channel/abc", :youtube],
      ["youtube.com/playlist?list=abc", :youtube]
    ]

    invalid_values.each do |value, platform|
      expect { described_class.normalize(value, platform:) }.to raise_error(described_class::Invalid)
    end
  end
end
