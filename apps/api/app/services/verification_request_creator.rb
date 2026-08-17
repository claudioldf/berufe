# frozen_string_literal: true

class VerificationRequestCreator
  class Invalid < StandardError
    attr_reader :field_errors

    def initialize(field_errors)
      @field_errors = field_errors
      super("invalid verification request")
    end
  end

  def call(profile:, media_upload_id:, verification_type:, now: Time.current)
    profile.with_lock do
      validate_type!(verification_type)
      upload = profile.media_uploads.lock.find(media_upload_id)
      existing = VerificationFile.find_by(media_upload_id: upload.id)&.verification_request
      return existing if existing&.professional_profile_id == profile.id

      validate_upload!(upload)
      ensure_no_pending_request!(profile, verification_type)
      request = profile.verification_requests.create!(
        verification_type:,
        status: "pending_review",
        submitted_at: now
      )
      request.create_verification_file!(
        media_upload: upload,
        private_key: upload.sanitized_key,
        content_type: upload.sanitized_content_type,
        byte_size: upload.sanitized_byte_size,
        width: upload.width,
        height: upload.height,
        uploaded_at: now
      )
      upload.update!(state: "attached", attached_at: now)
      request
    end
  rescue ActiveRecord::RecordInvalid => error
    raise Invalid.new(error.record.errors.to_hash(true))
  end

  private

  def validate_type!(verification_type)
    return if verification_type == "identity"

    raise Invalid.new(verification_type: ["não é suportado"])
  end

  def validate_upload!(upload)
    errors = []
    errors << "deve ser um envio de identidade" unless upload.purpose == "verification_identity"
    errors << "a imagem ainda não terminou de processar" unless upload.processed?
    unless upload.sanitized_content_type.in?(MediaUpload::SUPPORTED_CONTENT_TYPES)
      errors << "a imagem processada não é suportada"
    end
    raise Invalid.new(media_upload_id: errors) if errors.any?
  end

  def ensure_no_pending_request!(profile, verification_type)
    return unless profile.verification_requests.exists?(
      verification_type:,
      status: "pending_review"
    )

    raise Invalid.new(verification_type: ["já possui uma solicitação em análise"])
  end
end
