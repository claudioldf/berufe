# frozen_string_literal: true

require "rails_helper"

RSpec.describe PublicProfilePhotoImageUrl do
  it "builds a Rails-owned public media URL without exposing a storage key" do
    photo = Struct.new(:id).new("15ff05bf-3c8a-4bcf-a410-f6b8d55ba2f8")

    expect(described_class.call(photo, environment: {"API_PUBLIC_URL" => "https://api.berufe.test/"})).to eq(
      "https://api.berufe.test/api/v1/public/profile-photos/15ff05bf-3c8a-4bcf-a410-f6b8d55ba2f8/image"
    )
  end
end
