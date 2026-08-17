# frozen_string_literal: true

class VerificationFileReader
  class Unavailable < StandardError; end

  Result = Data.define(:body, :content_type, :filename)

  def initialize(
    context: Current.admin_action_context,
    storage: MediaStorage.build,
    validator: RegeneratedImageValidator.new
  )
    @context = context
    @storage = storage
    @validator = validator
  end

  def call(id:)
    file = VerificationFile.includes(:media_upload).find(id)
    validate_record!(file)
    body = storage.read(scope: :private, key: file.private_key)
    validator.call(
      body:,
      content_type: file.content_type,
      byte_size: file.byte_size,
      width: file.width,
      height: file.height
    )
    VerificationFileAccessEvent.create!(
      verification_file: file,
      admin_user_id: context.admin_user_id,
      action: "viewed",
      request_id: context.request_id,
      created_at: Time.current
    )
    extension = (file.content_type == "image/png") ? "png" : "jpg"
    Result.new(
      body:,
      content_type: file.content_type,
      filename: "berufe-identidade-#{file.id}.#{extension}"
    )
  rescue RegeneratedImageValidator::Invalid
    raise Unavailable
  end

  private

  attr_reader :context, :storage, :validator

  def validate_record!(file)
    upload = file.media_upload
    valid = file.deleted_at.nil? &&
      upload.attached? &&
      upload.purpose == "verification_identity" &&
      upload.sanitized_key == file.private_key &&
      upload.sanitized_content_type == file.content_type &&
      upload.sanitized_byte_size == file.byte_size &&
      upload.width == file.width &&
      upload.height == file.height
    raise Unavailable unless valid
  end
end
