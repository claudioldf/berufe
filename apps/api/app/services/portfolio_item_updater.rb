# frozen_string_literal: true

class PortfolioItemUpdater
  class Invalid < StandardError
    attr_reader :field_errors

    def initialize(field_errors)
      @field_errors = field_errors
      super("invalid portfolio item")
    end
  end

  def call(profile:, item:, attributes:, now: Time.current)
    ApplicationRecord.transaction do
      profile.lock!
      item.lock!
      raise ActiveRecord::RecordNotFound unless item.professional_profile_id == profile.id && item.deleted_at.nil?

      upload = replacement_upload(profile, attributes[:media_upload_id])
      item.assign_attributes(
        service: selected_service!(profile, attributes.fetch(:service_id)),
        title: attributes[:title].to_s.squish,
        description: attributes[:description].to_s.squish.presence,
        submitted_at: now
      )
      assign_replacement_image!(item, upload) if upload
      item.save!
      upload&.update!(state: "attached", attached_at: now)
    end

    item.reload
  rescue ActiveRecord::RecordInvalid => error
    raise Invalid.new(error.record.errors.to_hash(true))
  end

  private

  def replacement_upload(profile, media_upload_id)
    return if media_upload_id.blank?

    upload = profile.media_uploads.lock.find(media_upload_id)
    existing = PortfolioItem.find_by(media_upload_id: upload.id)
    raise Invalid.new(media_upload_id: ["já foi usado"]) if existing

    validate_upload!(upload)
    upload
  end

  def validate_upload!(upload)
    errors = []
    errors << "deve ser um envio de portfólio" unless upload.purpose == "portfolio_image"
    errors << "a imagem ainda não terminou de processar" unless upload.processed?
    unless upload.sanitized_content_type.in?(MediaUpload::SUPPORTED_CONTENT_TYPES)
      errors << "a imagem processada não é suportada"
    end
    raise Invalid.new(media_upload_id: errors) if errors.any?
  end

  def selected_service!(profile, service_id)
    selection = profile.working_revision.professional_profile_services
      .includes(:service)
      .find_by(service_id:)
    service = selection&.service
    return service if service&.is_active?

    raise Invalid.new(service_id: ["deve ser um serviço ativo selecionado no perfil"])
  end

  def assign_replacement_image!(item, upload)
    item.assign_attributes(
      media_upload: upload,
      private_key: upload.sanitized_key,
      content_type: upload.sanitized_content_type,
      byte_size: upload.sanitized_byte_size,
      width: upload.width,
      height: upload.height
    )
  end
end
