# frozen_string_literal: true

require_relative "../../app/services/r2_storage"

RSpec.describe R2Storage do
  subject(:storage) do
    described_class.new(
      endpoint: "https://account.r2.cloudflarestorage.com",
      access_key_id: "access-key",
      secret_access_key: "secret-key",
      public_bucket: "public-media",
      private_bucket: "private-media",
      client:
    )
  end

  let(:client) { instance_double(Aws::S3::Client) }

  it "keeps public and private objects in their configured buckets" do
    expect(client).to receive(:put_object).with(
      bucket: "private-media",
      key: "quarantine/image.jpg",
      body: "synthetic",
      content_type: "image/jpeg"
    )

    expect(storage.write(scope: :private, key: "quarantine/image.jpg", body: "synthetic", content_type: "image/jpeg"))
      .to eq("quarantine/image.jpg")
  end

  it "rejects unknown storage scopes before calling R2" do
    expect { storage.delete(scope: :unknown, key: "image.jpg") }
      .to raise_error(ArgumentError, "invalid storage scope")
  end
end
