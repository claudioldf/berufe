# frozen_string_literal: true

class ProfessionalProfilePhotoAttacher
  class Invalid < StandardError
    attr_reader :field_errors

    def initialize(field_errors)
      @field_errors = field_errors
      super("invalid profile photo")
    end
  end

  def call(profile:, media_upload_id:, now: Time.current)
    profile.with_lock do
      upload = profile.media_uploads.lock.find(media_upload_id)
      existing = profile.profile_photos.find_by(media_upload_id: upload.id)
      return existing if existing

      validate_upload!(upload)
      supersede_pending_photo!(profile.working_photo, now:)
      photo = profile.profile_photos.create!(
        media_upload: upload,
        status: "pending_review",
        private_key: upload.sanitized_key,
        content_type: upload.sanitized_content_type,
        byte_size: upload.sanitized_byte_size,
        width: upload.width,
        height: upload.height,
        submitted_at: now
      )
      upload.update!(state: "attached", attached_at: now)
      profile.update!(working_photo: photo)
      photo
    end
  rescue ActiveRecord::RecordInvalid => error
    raise Invalid.new(error.record.errors.to_hash(true))
  end

  private

  def validate_upload!(upload)
    errors = []
    errors << "deve ser um envio de foto de perfil" unless upload.purpose == "profile_photo"
    errors << "a imagem ainda não terminou de processar" unless upload.processed?
    errors << "a imagem processada deve ser JPEG" unless upload.sanitized_content_type == "image/jpeg"
    errors << "a imagem processada está fora das dimensões permitidas" unless valid_dimensions?(upload)
    raise Invalid.new(media_upload_id: errors) if errors.any?
  end

  def valid_dimensions?(upload)
    upload.width.to_i.between?(1, 1024) && upload.height.to_i.between?(1, 1536)
  end

  def supersede_pending_photo!(photo, now:)
    return unless photo&.pending_review?

    photo.update!(status: "superseded", reviewed_at: now)
  end
end
