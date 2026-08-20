# frozen_string_literal: true

class ModerationQueueQuery
  TYPES = %w[
    all profile_revision profile_photo portfolio_item verification_request professional_relationship
  ].freeze
  STATUSES = %w[pending_review approved rejected hidden all].freeze
  DEFAULT_PER_PAGE = 20
  MAX_PER_PAGE = 50

  class Invalid < StandardError
    attr_reader :field_errors

    def initialize(field_errors)
      @field_errors = field_errors
      super("invalid moderation queue filters")
    end
  end

  def call(type: "all", status: "pending_review", search: nil, page: 1, per_page: DEFAULT_PER_PAGE)
    filters = normalized_filters(type:, status:, search:, page:, per_page:)
    entries = load_entries(filters[:type], filters[:status])
      .select { |entry| search_match?(entry, filters[:search]) }
      .sort_by { |entry| [entry.fetch(:submitted_at), entry.fetch(:target_id)] }

    total_count = entries.length
    offset = (filters[:page] - 1) * filters[:per_page]
    {
      items: entries.slice(offset, filters[:per_page]) || [],
      meta: {
        page: filters[:page],
        per_page: filters[:per_page],
        total_count:,
        total_pages: total_count.zero? ? 0 : (total_count.to_f / filters[:per_page]).ceil
      },
      summary: ModerationQueueSummaryQuery.new.call
    }
  end

  private

  def normalized_filters(type:, status:, search:, page:, per_page:)
    normalized_type = type.to_s.presence || "all"
    normalized_status = status.to_s.presence || "pending_review"
    normalized_page = Integer(page.to_s.presence || 1, exception: false)
    normalized_per_page = Integer(per_page.to_s.presence || DEFAULT_PER_PAGE, exception: false)
    errors = {}
    errors[:type] = ["use um tipo de moderação válido"] unless TYPES.include?(normalized_type)
    errors[:status] = ["use um status de moderação válido"] unless STATUSES.include?(normalized_status)
    errors[:search] = ["use uma busca com até 100 caracteres"] if search.to_s.length > 100
    errors[:page] = ["deve ser maior que zero"] unless normalized_page&.positive?
    unless normalized_per_page&.between?(1, MAX_PER_PAGE)
      errors[:per_page] = ["deve estar entre 1 e #{MAX_PER_PAGE}"]
    end
    raise Invalid.new(errors) if errors.any?

    {
      type: normalized_type,
      status: normalized_status,
      search: normalize_search(search),
      page: normalized_page,
      per_page: normalized_per_page
    }
  end

  def load_entries(type, status)
    loaders = {
      "profile_revision" => method(:profile_revisions),
      "profile_photo" => method(:profile_photos),
      "portfolio_item" => method(:portfolio_items),
      "verification_request" => method(:verification_requests),
      "professional_relationship" => method(:professional_relationships)
    }
    selected = (type == "all") ? loaders.values : [loaders.fetch(type)]
    selected.flat_map { |loader| loader.call(status) }
  end

  def profile_revisions(status)
    scope = ProfessionalProfileRevision.includes(
      professional_profile: %i[published_revision approved_revision published_photo user_account],
      professional_profile_services: :service,
      professional_profile_service_areas: :neighborhood
    )
    scope = if status == "hidden"
      scope.joins(:professional_profile).where(
        "professional_profiles.profile_status = ? AND professional_profiles.published_revision_id = professional_profile_revisions.id",
        "suspended"
      )
    elsif status == "all"
      scope.where(status: %w[pending_review approved rejected])
    else
      scope.where(status:)
    end
    scope.filter_map do |revision|
      effective_status = (revision.professional_profile.profile_status == "suspended" &&
        revision.professional_profile.published_revision_id == revision.id) ? "hidden" : revision.status
      next unless status.in?(%w[all hidden]) || effective_status == status

      profile_entry(revision, effective_status)
    end
  end

  def profile_photos(status)
    scope = ProfessionalProfilePhoto.includes(
      professional_profile: %i[working_revision approved_photo published_revision published_photo user_account]
    )
    scope = scope.where(status: moderated_statuses(status, ProfessionalProfilePhoto::STATUSES))
    scope.map { |photo| photo_entry(photo) }
  end

  def portfolio_items(status)
    scope = PortfolioItem.active.includes(
      :service,
      professional_profile: %i[working_revision published_revision published_photo user_account]
    )
    scope = scope.where(status: moderated_statuses(status, PortfolioItem::STATUSES))
    scope.map { |item| portfolio_entry(item) }
  end

  def verification_requests(status)
    allowed = VerificationRequest::STATUSES & %w[pending_review approved rejected]
    statuses = moderated_statuses(status, allowed)
    return [] if statuses.empty?

    VerificationRequest.includes(:verification_file, professional_profile: :working_revision)
      .where(status: statuses)
      .map { |request_record| verification_entry(request_record) }
  end

  def professional_relationships(status)
    statuses = moderated_statuses(status, ProfessionalRelationship::MODERATION_STATUSES)
    return [] if statuses.empty?

    ProfessionalRelationship
      .where(status: "accepted", moderation_status: statuses)
      .includes(
        initiator_professional: %i[published_revision working_revision],
        recipient_professional: %i[published_revision working_revision]
      )
      .map { |relationship| relationship_entry(relationship, relationship.moderation_status) }
  end

  def moderated_statuses(status, allowed)
    return allowed & %w[pending_review approved rejected hidden] if status == "all"
    return [] unless allowed.include?(status)

    [status]
  end

  def profile_entry(revision, status)
    {
      target_type: "profile_revision",
      target_id: revision.id,
      status:,
      title: "Perfil · #{revision.display_name}",
      subtitle: supply_subtitle(revision),
      submitted_at: revision.submitted_at || revision.created_at,
      details: revision.professional_profile.published_revision_id.present? ?
        "O conteúdo atual está público enquanto aguarda revisão." :
        "O conteúdo não está público porque não há uma revisão válida atual.",
      preview: [revision.headline, revision.bio].compact_blank.join(" — "),
      currently_public: currently_public_revision?(revision),
      fallback_available: revision.professional_profile.approved_revision.present?,
      changes: profile_changes(revision),
      claimed_birthdate: nil,
      has_media: false,
      verification_file_id: nil
    }
  end

  def photo_entry(photo)
    revision = photo.professional_profile.working_revision
    {
      target_type: "profile_photo",
      target_id: photo.id,
      status: photo.status,
      title: "Foto de perfil · #{revision.display_name}",
      subtitle: supply_subtitle(revision),
      submitted_at: photo.submitted_at,
      details: "Foto de perfil regenerada e enviada para conferência manual.",
      preview: "Imagem privada · acesso registrado na trilha de auditoria",
      currently_public: currently_public_photo?(photo),
      fallback_available: photo.professional_profile.approved_photo.present?,
      changes: [],
      claimed_birthdate: nil,
      has_media: true,
      verification_file_id: nil
    }
  end

  def portfolio_entry(item)
    revision = item.professional_profile.working_revision
    {
      target_type: "portfolio_item",
      target_id: item.id,
      status: item.status,
      title: "#{item.title} · #{revision.display_name}",
      subtitle: [item.service.name, coverage_label(revision)].compact_blank.join(" · "),
      submitted_at: item.submitted_at,
      details: "Nova imagem de portfólio associada ao serviço #{item.service.name}.",
      preview: item.description.presence || item.title,
      currently_public: !!(
        item.status.in?(%w[pending_review approved]) && item.professional_profile.publicly_available?
      ),
      fallback_available: false,
      changes: [],
      claimed_birthdate: nil,
      has_media: true,
      verification_file_id: nil
    }
  end

  def verification_entry(request_record)
    revision = request_record.professional_profile.working_revision
    {
      target_type: "verification_request",
      target_id: request_record.id,
      status: request_record.status,
      title: "Identidade · #{revision.display_name}",
      subtitle: supply_subtitle(revision),
      submitted_at: request_record.submitted_at,
      details: "Imagem de identidade enviada para conferência manual.",
      preview: "Arquivo privado · acesso registrado na trilha de auditoria",
      currently_public: false,
      fallback_available: false,
      changes: [],
      claimed_birthdate: request_record.claimed_birthdate&.iso8601,
      has_media: false,
      verification_file_id: request_record.verification_file&.id
    }
  end

  def relationship_entry(relationship, status)
    initiator = relationship.initiator_professional
    recipient = relationship.recipient_professional
    type_label = if relationship.relationship_type == "recommendation"
      "Recomendação"
    else
      "Trabalharam juntos"
    end

    {
      target_type: "professional_relationship",
      target_id: relationship.id,
      status:,
      title: "Relação profissional · #{profile_name(initiator)} e #{profile_name(recipient)}",
      subtitle: type_label,
      submitted_at: relationship.responded_at,
      details: "Relação confirmada pelo destinatário e enviada para análise manual.",
      preview: relationship.context_note.presence || "Sem contexto adicional.",
      currently_public: PublicProfessionalRelationshipQuery.call.where(id: relationship.id).exists?,
      fallback_available: false,
      changes: [],
      claimed_birthdate: nil,
      has_media: false,
      verification_file_id: nil
    }
  end

  def supply_subtitle(revision)
    primary = revision.professional_profile_services.find(&:is_primary?)&.service&.name
    [primary, coverage_label(revision)].compact_blank.join(" · ")
  end

  def coverage_label(revision)
    areas = revision.professional_profile_service_areas
    return "Toda Joinville" if areas.any? { |area| area.neighborhood_code.nil? }

    areas.filter_map { |area| area.neighborhood&.name }.join(", ")
  end

  def profile_name(profile)
    (profile.published_revision || profile.working_revision).display_name
  end

  def currently_public_revision?(revision)
    profile = revision.professional_profile
    !!(profile.published_revision_id == revision.id && profile.publicly_available?)
  end

  def currently_public_photo?(photo)
    profile = photo.professional_profile
    !!(profile.published_photo_id == photo.id && profile.publicly_available?)
  end

  def profile_changes(revision)
    fallback = revision.professional_profile.approved_revision
    before = fallback&.material_snapshot || {}
    after = revision.material_snapshot
    (before.keys | after.keys).filter_map do |field|
      next if before[field] == after[field]

      {field: field.to_s, before: before[field], after: after[field]}
    end
  end

  def search_match?(entry, search)
    return true if search.blank?

    normalize_search(
      [entry[:target_type], entry[:target_id], entry[:title], entry[:subtitle], entry[:status]].join(" ")
    ).include?(search)
  end

  def normalize_search(value)
    I18n.transliterate(value.to_s).downcase.squish
  end
end
