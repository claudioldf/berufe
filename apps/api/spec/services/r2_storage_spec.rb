# frozen_string_literal: true

require_relative "../../app/services/r2_storage"

RSpec.describe R2Storage do
  subject(:storage) do
    described_class.new(
      endpoint: "https://account.r2.cloudflarestorage.com",
      access_key_id: "access-key",
      secret_access_key: "secret-key",
      private_bucket: "private-media",
      client:,
      presigner:
    )
  end

  let(:client) { instance_double(Aws::S3::Client) }
  let(:presigner) { instance_double(Aws::S3::Presigner) }

  it "uses checksum settings compatible with R2" do
    expect(Aws::S3::Client).to receive(:new).with(
      endpoint: "https://account.r2.cloudflarestorage.com",
      access_key_id: "access-key",
      secret_access_key: "secret-key",
      region: "auto",
      force_path_style: true,
      request_checksum_calculation: "when_required",
      response_checksum_validation: "when_required"
    ).and_return(client)
    expect(Aws::S3::Presigner).to receive(:new).with(client:).and_return(presigner)

    described_class.new(
      endpoint: "https://account.r2.cloudflarestorage.com",
      access_key_id: "access-key",
      secret_access_key: "secret-key",
      private_bucket: "private-media"
    )
  end

  it "keeps media objects in the configured private bucket" do
    expect(client).to receive(:put_object).with(
      bucket: "private-media",
      key: "quarantine/image.jpg",
      body: "synthetic",
      content_type: "image/jpeg"
    )

    expect(storage.write(scope: :private, key: "quarantine/image.jpg", body: "synthetic", content_type: "image/jpeg"))
      .to eq("quarantine/image.jpg")
  end

  it "returns downloaded object bytes with binary encoding" do
    payload = "\xFF\xD8\xFF\xE0".dup.force_encoding(Encoding::UTF_8)
    response = instance_double(
      Aws::S3::Types::GetObjectOutput,
      body: StringIO.new(payload)
    )
    expect(client).to receive(:get_object)
      .with(bucket: "private-media", key: "quarantine/image.jpg")
      .and_return(response)

    body = storage.read(scope: :private, key: "quarantine/image.jpg")

    expect(body.bytes).to eq(payload.bytes)
    expect(body.encoding).to eq(Encoding::BINARY)
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
