# frozen_string_literal: true

class ModerationMediaPublisher
  def initialize(storage: MediaStorage.build)
    @storage = storage
  end

  def publish(target:, target_type:)
    extension = (target.content_type == "image/png") ? "png" : "jpg"
    public_key = "moderation/#{target_type}/#{target.id}/#{SecureRandom.uuid}.#{extension}"
    body = storage.read(scope: :private, key: target.private_key)
    storage.write(scope: :public, key: public_key, body:, content_type: target.content_type)
    public_key
  end

  def delete(public_key)
    storage.delete(scope: :public, key: public_key) if public_key.present?
  end

  private

  attr_reader :storage
end
