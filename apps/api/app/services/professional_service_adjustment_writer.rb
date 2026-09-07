# frozen_string_literal: true

class ProfessionalServiceAdjustmentWriter
  class Unavailable < StandardError; end
  class Stale < StandardError; end

  class Invalid < StandardError
    attr_reader :field_errors

    def initialize(field_errors)
      @field_errors = field_errors
      super("invalid service adjustment")
    end
  end

  FIELDS = %i[title description schedule_impact incurred_on].freeze
  ITEM_FIELDS = %i[kind description quantity unit unit_price].freeze

  def call(service_job:, attributes:, adjustment: nil, now: Time.current)
    created = adjustment.nil?

    ApplicationRecord.transaction do
      service_job.lock!
      if created
        raise Unavailable unless service_job.approved?

        adjustment = service_job.service_adjustments.new(
          adjustment_number: service_job.service_adjustments.maximum(:adjustment_number).to_i + 1
        )
      else
        adjustment.lock!
        raise ActiveRecord::RecordNotFound unless adjustment.service_job_id == service_job.id
        raise Unavailable unless adjustment.editable?
        raise Stale if attributes[:revision].nil? || attributes[:revision].to_i != adjustment.lock_version
      end

      reusable_receipts = adjustment.service_adjustment_items
        .includes(:service_adjustment_receipt)
        .filter_map(&:service_adjustment_receipt)
        .index_by(&:media_upload_id)

      adjustment.service_adjustment_items.destroy_all unless created
      reset_for_edit!(adjustment) unless created
      adjustment.assign_attributes(attributes.slice(*FIELDS))

      receipt_requests = []
      Array(attributes[:items]).each_with_index do |item_attributes, sort_order|
        normalized = item_attributes.to_h.symbolize_keys
        item = adjustment.service_adjustment_items.build(
          normalized.slice(*ITEM_FIELDS).merge(sort_order:)
        )
        receipt_requests << [item, normalized[:media_upload_id]] if normalized[:media_upload_id].present?
      end

      adjustment.save!
      receipt_requests.each_with_index do |(item, upload_id), index|
        attach_receipt!(
          service_job:,
          item:,
          upload_id:,
          reusable_receipt: reusable_receipts[upload_id.to_s],
          index:,
          now:
        )
      end
    end

    adjustment.reload
  rescue ActiveRecord::RecordInvalid => error
    raise Invalid.new(error.record.errors.to_hash(true))
  end

  private

  def reset_for_edit!(adjustment)
    adjustment.assign_attributes(
      status: "draft",
      shared_at: nil,
      customer_decided_at: nil,
      customer_decision_message: nil,
      terms_accepted_at: nil,
      accepted_revision: nil,
      accepted_customer_name: nil,
      accepted_customer_phone_e164: nil,
      accepted_customer_email: nil
    )
  end

  def attach_receipt!(service_job:, item:, upload_id:, reusable_receipt:, index:, now:)
    unless item.reimbursement?
      raise Invalid.new("items.#{index}.media_upload_id": ["só pode ser usado em reembolso de material"])
    end

    profile = service_job.professional
    upload = profile.media_uploads.lock.find(upload_id)
    unless valid_new_upload?(upload) || reusable_receipt&.media_upload_id == upload.id
      raise Invalid.new("items.#{index}.media_upload_id": ["não é um comprovante processado disponível"])
    end

    item.create_service_adjustment_receipt!(
      media_upload: upload,
      private_key: upload.sanitized_key,
      content_type: upload.sanitized_content_type,
      byte_size: upload.sanitized_byte_size,
      width: upload.width,
      height: upload.height,
      attached_at: reusable_receipt&.attached_at || now
    )
    upload.update!(state: "attached", attached_at: now) unless upload.attached?
  end

  def valid_new_upload?(upload)
    upload.purpose == "service_adjustment_receipt" &&
      upload.processed? &&
      upload.sanitized_key.present? &&
      upload.sanitized_content_type.in?(MediaUpload::SUPPORTED_CONTENT_TYPES)
  end
end
