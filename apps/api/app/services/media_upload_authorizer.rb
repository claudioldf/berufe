# frozen_string_literal: true

class MediaUploadAuthorizer
  class Invalid < StandardError
    attr_reader :field_errors

    def initialize(field_errors)
      @field_errors = field_errors
      super("invalid media upload authorization")
    end
  end

  class Unavailable < StandardError; end

  def call(profile:, purpose:, content_type:, byte_size:, now: Time.current)
    attributes = normalize(purpose:, content_type:, byte_size:)
    validate!(attributes)

    upload = profile.media_uploads.new(
      **attributes,
      state: "authorized",
      quarantine_key: "quarantine/#{profile.id}/#{SecureRandom.uuid}",
      authorization_expires_at: now + MediaUpload::AUTHORIZATION_TTL
    )

    upload.transaction do
      upload.save!
      [upload, upload_instruction(upload, now:)]
    end
  rescue ActiveRecord::RecordInvalid => error
    raise Invalid.new(error.record.errors.to_hash(true))
  rescue Invalid
    raise
  rescue => error
    raise Unavailable, error.message
  end

  private

  def normalize(purpose:, content_type:, byte_size:)
    {
      purpose: purpose.to_s,
      declared_content_type: content_type.to_s.downcase.strip,
      declared_byte_size: Integer(byte_size, exception: false)
    }
  end

  def validate!(attributes)
    errors = {}
    errors[:purpose] = ["não é suportado"] unless attributes[:purpose].in?(MediaUpload::PURPOSES)
    unless attributes[:declared_content_type].in?(MediaUpload::SUPPORTED_CONTENT_TYPES)
      errors[:content_type] = ["deve ser JPEG ou PNG"]
    end
    unless attributes[:declared_byte_size].in?(1..MediaUpload::MAX_BYTE_SIZE)
      errors[:byte_size] = ["deve estar entre 1 byte e 10 MiB"]
    end
    raise Invalid.new(errors) if errors.any?
  end

  def upload_instruction(upload, now:)
    headers = {"Content-Type" => upload.declared_content_type}
    if Rails.configuration.x.berufe.environment.media_storage_adapter == "r2"
      storage = MediaStorage.build
      expires_in = (upload.authorization_expires_at - now).ceil
      {
        strategy: "direct",
        method: "PUT",
        url: storage.presigned_put_url(
          scope: :private,
          key: upload.quarantine_key,
          content_type: upload.declared_content_type,
          expires_in:
        ),
        headers:
      }
    else
      api_base_url = ENV.fetch("API_PUBLIC_URL", "").delete_suffix("/")
      {
        strategy: "rails",
        method: "PUT",
        url: "#{api_base_url}/api/v1/professional/media-uploads/#{upload.id}/content",
        headers:
      }
    end
  end
end
