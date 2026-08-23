# frozen_string_literal: true

class MediaUploadProcessor
  def initialize(inspector: MediaUploadInspector.new)
    @inspector = inspector
  end

  def call(upload:, now: Time.current, storage: MediaStorage.build)
    return upload unless start_processing(upload, now:)

    body = storage.read(scope: :private, key: upload.quarantine_key)
    result = @inspector.call(
      body:,
      declared_content_type: upload.declared_content_type,
      purpose: upload.purpose
    )
    sanitized_key = sanitized_key_for(upload, result.sanitized_content_type)
    upload.with_lock do
      storage.write(
        scope: :private,
        key: sanitized_key,
        body: result.sanitized_body,
        content_type: result.sanitized_content_type
      )
      upload.update!(
        state: "processed",
        actual_content_type: result.content_type,
        sanitized_content_type: result.sanitized_content_type,
        actual_byte_size: result.byte_size,
        sanitized_byte_size: result.sanitized_body.bytesize,
        width: result.width,
        height: result.height,
        sanitized_key:,
        failure_code: nil,
        processed_at: now
      )
      storage.delete(scope: :private, key: upload.quarantine_key)
    end
    upload
  rescue MediaUploadInspector::Invalid => error
    fail_invalid(upload, code: error.code, storage:)
  rescue => error
    failure_code = storage_error?(error) ? "storage_unavailable" : "processing_unavailable"
    Rails.error.report(error, context: {media_upload_id: upload.id, failure_code:})
    fail_transient(upload, code: failure_code)
  end

  private

  def start_processing(upload, now:)
    upload.with_lock do
      return false unless upload.uploaded?

      upload.update!(
        state: "processing",
        processing_started_at: now,
        processing_attempts: upload.processing_attempts + 1,
        failure_code: nil
      )
    end
    true
  end

  def sanitized_key_for(upload, content_type)
    extension = (content_type == "image/png") ? "png" : "jpg"
    "sanitized/#{upload.professional_profile_id}/#{upload.id}.#{extension}"
  end

  def fail_invalid(upload, code:, storage:)
    upload.update!(state: "failed", failure_code: code)
    storage.delete(scope: :private, key: upload.quarantine_key)
    upload
  rescue
    fail_transient(upload, code: "storage_unavailable")
  end

  def fail_transient(upload, code:)
    upload.update!(state: "failed", failure_code: code) if upload.persisted?
    upload
  end

  def storage_error?(error)
    error.is_a?(SystemCallError) || error.class.name.start_with?("Aws::", "Seahorse::")
  end
end
