# frozen_string_literal: true

class MediaUploadSerializer
  def initialize(upload)
    @upload = upload
  end

  def as_json(*)
    {
      id: @upload.id,
      purpose: @upload.purpose,
      state: @upload.state,
      declared_content_type: @upload.declared_content_type,
      declared_byte_size: @upload.declared_byte_size,
      actual_content_type: @upload.actual_content_type,
      actual_byte_size: @upload.actual_byte_size,
      width: @upload.width,
      height: @upload.height,
      failure_code: @upload.failure_code,
      retryable: @upload.retryable?,
      authorization_expires_at: @upload.authorization_expires_at.iso8601
    }
  end
end
