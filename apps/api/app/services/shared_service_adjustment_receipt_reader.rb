# frozen_string_literal: true

class SharedServiceAdjustmentReceiptReader
  class NotFound < StandardError; end

  Result = Data.define(:body, :content_type, :filename)

  def initialize(storage: MediaStorage.build, validator: RegeneratedImageValidator.new)
    @storage = storage
    @validator = validator
  end

  def call(token:, receipt_id:)
    resolved = SharedQuoteResolver.new.call(token:)
    service_job = resolved.quote.service_job
    raise NotFound unless service_job

    receipt = ServiceAdjustmentReceipt
      .joins(service_adjustment_item: :service_adjustment)
      .includes(:media_upload)
      .where.not(service_adjustments: {status: "draft"})
      .find_by(
        id: receipt_id,
        service_adjustments: {service_job_id: service_job.id}
      )
    raise NotFound unless receipt

    validate_record!(receipt)
    body = @storage.read(scope: :private, key: receipt.private_key)
    @validator.call(
      body:,
      content_type: receipt.content_type,
      byte_size: receipt.byte_size,
      width: receipt.width,
      height: receipt.height
    )
    extension = (receipt.content_type == "image/png") ? "png" : "jpg"
    Result.new(body:, content_type: receipt.content_type, filename: "berufe-comprovante-#{receipt.id}.#{extension}")
  rescue SharedQuoteResolver::NotFound
    raise NotFound
  rescue RegeneratedImageValidator::Invalid
    raise NotFound
  end

  private

  def validate_record!(receipt)
    upload = receipt.media_upload
    valid = upload.attached? &&
      upload.purpose == "service_adjustment_receipt" &&
      upload.sanitized_key == receipt.private_key &&
      upload.sanitized_content_type == receipt.content_type &&
      upload.sanitized_byte_size == receipt.byte_size &&
      upload.width == receipt.width &&
      upload.height == receipt.height
    raise NotFound unless valid
  end
end
