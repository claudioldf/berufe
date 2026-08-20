# frozen_string_literal: true

require "aws-sdk-s3"

class R2Storage
  def initialize(
    endpoint:,
    access_key_id:,
    secret_access_key:,
    public_bucket:,
    private_bucket:,
    client: nil,
    presigner: nil
  )
    @buckets = {"public" => public_bucket, "private" => private_bucket}.freeze
    @client = client || Aws::S3::Client.new(
      endpoint:,
      access_key_id:,
      secret_access_key:,
      region: "auto",
      force_path_style: true
    )
    @presigner = presigner || Aws::S3::Presigner.new(client: @client)
  end

  def write(scope:, key:, body:, content_type: "application/octet-stream", cache_control: nil)
    options = {bucket: bucket_for(scope), key:, body:, content_type:}
    options[:cache_control] = cache_control if cache_control
    @client.put_object(**options)
    key
  end

  def read(scope:, key:)
    @client.get_object(bucket: bucket_for(scope), key:).body.read
  end

  def delete(scope:, key:)
    @client.delete_object(bucket: bucket_for(scope), key:)
  end

  def stat(scope:, key:)
    object = @client.head_object(bucket: bucket_for(scope), key:)
    {byte_size: object.content_length, content_type: object.content_type}
  end

  def presigned_put_url(scope:, key:, content_type:, expires_in:)
    @presigner.presigned_url(
      :put_object,
      bucket: bucket_for(scope),
      key:,
      content_type:,
      expires_in:
    )
  end

  private

  def bucket_for(scope)
    @buckets.fetch(scope.to_s) { raise ArgumentError, "invalid storage scope" }
  end
end
