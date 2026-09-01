# frozen_string_literal: true

class PortfolioItemCreator
  MAX_ACTIVE_ITEMS = 12

  class Invalid < StandardError
    attr_reader :field_errors

    def initialize(field_errors)
      @field_errors = field_errors
      super("invalid portfolio item")
    end
  end

  def call(profile:, attributes:, now: Time.current)
    profile.with_lock do
      upload = profile.media_uploads.lock.find(attributes.fetch(:media_upload_id))
      existing = profile.portfolio_items.find_by(media_upload_id: upload.id)
      raise Invalid.new(media_upload_id: ["já foi usado"]) if existing

      validate_upload!(upload)
      service = selected_service!(profile, attributes.fetch(:service_id))
      enforce_limit!(profile)
      item = profile.portfolio_items.create!(
        media_upload: upload,
        service:,
        title: attributes[:title].to_s.squish,
        description: attributes[:description].to_s.squish.presence,
        private_key: upload.sanitized_key,
        content_type: upload.sanitized_content_type,
        byte_size: upload.sanitized_byte_size,
        width: upload.width,
        height: upload.height,
        submitted_at: now
      )
      upload.update!(state: "attached", attached_at: now)
      ProfessionalDailyActivity.increment!(
        professional_id: profile.id,
        counter: :evidence_creations,
        occurred_at: now
      )
      item
    end
  rescue ActiveRecord::RecordInvalid => error
    raise Invalid.new(error.record.errors.to_hash(true))
  end

  private

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
      .find_by(service_id: service_id)
    service = selection&.service
    return service if service&.is_active?

    raise Invalid.new(service_id: ["deve ser um serviço ativo selecionado no perfil"])
  end

  def enforce_limit!(profile)
    return if profile.portfolio_items.active.count < MAX_ACTIVE_ITEMS

    raise Invalid.new(base: ["o portfólio já possui 12 trabalhos"])
  end
end
