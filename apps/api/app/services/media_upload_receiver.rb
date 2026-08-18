# frozen_string_literal: true

class MediaUploadReceiver
  class Rejected < StandardError
    attr_reader :code

    def initialize(code)
      @code = code
      super
    end
  end

  class Unavailable < StandardError; end

  def call(upload:, body:, content_type:, now: Time.current, storage: MediaStorage.build)
    rejection_code = nil
    upload.with_lock do
      reject_state!(upload)
      if upload.authorization_expired?(now)
        expire!(upload, now:, storage:)
        rejection_code = "upload_expired"
      else
        normalized_type = content_type.to_s.downcase.strip
        rejection_code = validation_error(upload, body:, content_type: normalized_type)
        if rejection_code
          upload.update!(state: "failed", failure_code: rejection_code)
        else
          storage.write(
            scope: :private,
            key: upload.quarantine_key,
            body:,
            content_type: normalized_type
          )
          upload.update!(state: "uploaded", uploaded_at: now, failure_code: nil)
        end
      end
    end
    raise Rejected, rejection_code if rejection_code

    upload
  rescue Rejected
    raise
  rescue => error
    raise Unavailable, error.message
  end

  private

  def reject_state!(upload)
    return if upload.authorized?

    raise Rejected, "upload_not_authorized"
  end

  def expire!(upload, now:, storage:)
    storage.delete(scope: :private, key: upload.quarantine_key)
    upload.update!(state: "expired", failure_code: "authorization_expired", updated_at: now)
  end

  def validation_error(upload, body:, content_type:)
    return "content_type_mismatch" unless content_type == upload.declared_content_type
    return "byte_size_mismatch" unless body.bytesize == upload.declared_byte_size
    "byte_size_invalid" unless body.bytesize.in?(1..MediaUpload::MAX_BYTE_SIZE)
  end
end
