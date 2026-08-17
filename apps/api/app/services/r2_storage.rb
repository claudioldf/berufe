# frozen_string_literal: true

require "aws-sdk-s3"

class R2Storage
  def initialize(endpoint:, access_key_id:, secret_access_key:, public_bucket:, private_bucket:, client: nil)
    @buckets = {"public" => public_bucket, "private" => private_bucket}.freeze
    @client = client || Aws::S3::Client.new(
      endpoint:,
      access_key_id:,
      secret_access_key:,
      region: "auto",
      force_path_style: true
    )
  end

  def write(scope:, key:, body:, content_type: "application/octet-stream")
    @client.put_object(bucket: bucket_for(scope), key:, body:, content_type:)
    key
  end

  def read(scope:, key:)
    @client.get_object(bucket: bucket_for(scope), key:).body.read
  end

  def delete(scope:, key:)
    @client.delete_object(bucket: bucket_for(scope), key:)
  end

  private

  def bucket_for(scope)
    @buckets.fetch(scope.to_s) { raise ArgumentError, "invalid storage scope" }
  end
end
