# frozen_string_literal: true

class MediaUploadCompleter
  class Rejected < StandardError
    attr_reader :code

    def initialize(code)
      @code = code
      super
    end
  end

  class Unavailable < StandardError; end

  def call(upload:, now: Time.current, storage: MediaStorage.build)
    enqueue = false
    rejection_code = nil
    upload.with_lock do
      return upload if upload.processing? || upload.processed? || upload.attached?
      reject_state!(upload)
      if upload.authorization_expired?(now) && upload.authorized?
        expire!(upload, now:, storage:)
        rejection_code = "upload_expired"
      else
        object = storage.stat(scope: :private, key: upload.quarantine_key)
        if object_valid?(upload, object)
          upload.update!(state: "uploaded", uploaded_at: upload.uploaded_at || now, failure_code: nil)
          enqueue = true
        else
          storage.delete(scope: :private, key: upload.quarantine_key)
          upload.update!(state: "failed", failure_code: "uploaded_object_mismatch")
          rejection_code = "uploaded_object_mismatch"
        end
      end
    end
    raise Rejected, rejection_code if rejection_code

    MediaUploadProcessingJob.perform_later(upload.id) if enqueue
    upload
  rescue Errno::ENOENT, Aws::S3::Errors::NotFound
    reject_missing!(upload, storage:)
  rescue Rejected
    raise
  rescue => error
    raise Unavailable, error.message
  end

  private

  def reject_state!(upload)
    return if upload.authorized? || upload.uploaded?

    raise Rejected, "upload_not_completable"
  end

  def expire!(upload, now:, storage:)
    storage.delete(scope: :private, key: upload.quarantine_key)
    upload.update!(state: "expired", failure_code: "authorization_expired", updated_at: now)
  end

  def object_valid?(upload, object)
    actual_size = object.fetch(:byte_size)
    type_matches = object[:content_type].blank? || object[:content_type] == upload.declared_content_type
    actual_size == upload.declared_byte_size && actual_size.in?(1..MediaUpload::MAX_BYTE_SIZE) && type_matches
  end

  def reject_missing!(upload, storage:)
    upload.with_lock do
      storage.delete(scope: :private, key: upload.quarantine_key)
      upload.update!(state: "failed", failure_code: "upload_missing")
    end
    raise Rejected, "upload_missing"
  rescue Rejected
    raise
  rescue => error
    raise Unavailable, error.message
  end
end
