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
      client:,
      presigner:
    )
  end

  let(:client) { instance_double(Aws::S3::Client) }
  let(:presigner) { instance_double(Aws::S3::Presigner) }

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

  it "reads private object metadata and creates a content-type-bound upload URL" do
    head = instance_double(Aws::S3::Types::HeadObjectOutput, content_length: 123, content_type: "image/jpeg")
    expect(client).to receive(:head_object)
      .with(bucket: "private-media", key: "quarantine/image")
      .and_return(head)
    expect(presigner).to receive(:presigned_url).with(
      :put_object,
      bucket: "private-media",
      key: "quarantine/image",
      content_type: "image/jpeg",
      expires_in: 600
    ).and_return("https://r2.example/signed")

    expect(storage.stat(scope: :private, key: "quarantine/image")).to eq(
      byte_size: 123,
      content_type: "image/jpeg"
    )
    expect(
      storage.presigned_put_url(
        scope: :private,
        key: "quarantine/image",
        content_type: "image/jpeg",
        expires_in: 600
      )
    ).to eq("https://r2.example/signed")
  end
end
