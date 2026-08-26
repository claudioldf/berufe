# frozen_string_literal: true

require "rails_helper"

RSpec.describe PublicSearchEventDeduplication, type: :model do
  it "requires bounded digest and result-count values" do
    claim = described_class.new(
      subject_digest: "raw-ip",
      query_digest: "raw-query",
      result_count: -1,
      expires_at: nil
    )

    expect(claim).not_to be_valid
    expect(claim.errors).to include(:subject_digest, :query_digest, :result_count, :expires_at)
  end
end
