# frozen_string_literal: true

class MediaUploadRetry
  class Rejected < StandardError; end
  class Unavailable < StandardError; end

  def call(upload:, storage: MediaStorage.build)
    upload.with_lock do
      raise Rejected, "upload_not_retryable" unless upload.retryable?

      storage.stat(scope: :private, key: upload.quarantine_key)
      upload.update!(state: "uploaded", failure_code: nil)
    end
    MediaUploadProcessingJob.perform_later(upload.id)
    upload
  rescue Rejected
    raise
  rescue Errno::ENOENT, Aws::S3::Errors::NotFound
    upload.update!(state: "failed", failure_code: "upload_missing")
    raise Rejected, "upload_not_retryable"
  rescue => error
    raise Unavailable, error.message
  end
end
