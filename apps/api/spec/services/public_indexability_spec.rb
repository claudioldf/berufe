# frozen_string_literal: true

require "rails_helper"

RSpec.describe PublicIndexability do
  describe ".listing_indexable?" do
    it "requires at least the minimum published professionals" do
      expect(described_class.listing_indexable?(described_class::MINIMUM_LISTING_PROFESSIONALS - 1)).to eq(false)
      expect(described_class.listing_indexable?(described_class::MINIMUM_LISTING_PROFESSIONALS)).to eq(true)
      expect(described_class.listing_indexable?(nil)).to eq(false)
    end
  end

  describe ".profile_indexable?" do
    let(:base_profile) do
      {
        profile_type: "self_service",
        photo_url: "https://cdn.example.com/photo.jpg",
        headline: "Elétrica residencial.",
        bio: nil,
        portfolio: [],
        customer_recommendations: [],
        verification_labels: []
      }
    end

    it "is false without a serialized profile" do
      expect(described_class.profile_indexable?(nil)).to eq(false)
    end

    it "is false for an external (unclaimed, referral-created) profile regardless of evidence" do
      profile = base_profile.merge(
        profile_type: "external",
        portfolio: [{id: "1"}]
      )

      expect(described_class.profile_indexable?(profile)).to eq(false)
    end

    it "is false without a published photo" do
      profile = base_profile.merge(photo_url: nil, portfolio: [{id: "1"}])

      expect(described_class.profile_indexable?(profile)).to eq(false)
    end

    it "is false without a headline or a bio" do
      profile = base_profile.merge(headline: nil, bio: nil, portfolio: [{id: "1"}])

      expect(described_class.profile_indexable?(profile)).to eq(false)
    end

    it "is false with a headline and a photo but no evidence at all" do
      expect(described_class.profile_indexable?(base_profile)).to eq(false)
    end

    it "is true with a bio instead of a headline, given any one piece of evidence" do
      profile = base_profile.merge(headline: nil, bio: "Conto minha história.", portfolio: [{id: "1"}])

      expect(described_class.profile_indexable?(profile)).to eq(true)
    end

    it "is true with a portfolio item, a recommendation, or a verification label alone" do
      expect(described_class.profile_indexable?(base_profile.merge(portfolio: [{id: "1"}]))).to eq(true)
      expect(
        described_class.profile_indexable?(base_profile.merge(customer_recommendations: [{id: "1"}]))
      ).to eq(true)
      expect(
        described_class.profile_indexable?(base_profile.merge(verification_labels: [{type: "phone"}]))
      ).to eq(true)
    end
  end
end
