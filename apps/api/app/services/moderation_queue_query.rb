# frozen_string_literal: true

class ModerationQueueQuery
  TYPES = %w[all profile_revision profile_photo portfolio_item verification_request].freeze
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
      summary: summary
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
      "verification_request" => method(:verification_requests)
    }
    selected = (type == "all") ? loaders.values : [loaders.fetch(type)]
    selected.flat_map { |loader| loader.call(status) }
  end

  def profile_revisions(status)
    scope = ProfessionalProfileRevision.includes(
      professional_profile: :published_revision,
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
    scope = ProfessionalProfilePhoto.includes(professional_profile: :working_revision)
    scope = scope.where(status: moderated_statuses(status, ProfessionalProfilePhoto::STATUSES))
    scope.map { |photo| photo_entry(photo) }
  end

  def portfolio_items(status)
    scope = PortfolioItem.active.includes(:service, professional_profile: :working_revision)
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
        "O perfil voltou para análise após uma alteração material." :
        "Primeiro perfil enviado para análise e publicação.",
      preview: [revision.headline, revision.bio].compact_blank.join(" — "),
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
      has_media: false,
      verification_file_id: request_record.verification_file&.id
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

  def search_match?(entry, search)
    return true if search.blank?

    normalize_search(
      [entry[:target_type], entry[:target_id], entry[:title], entry[:subtitle], entry[:status]].join(" ")
    ).include?(search)
  end

  def normalize_search(value)
    I18n.transliterate(value.to_s).downcase.squish
  end

  def summary
    pending_times = [
      ProfessionalProfileRevision.where(status: "pending_review").minimum(:submitted_at),
      ProfessionalProfilePhoto.where(status: "pending_review").minimum(:submitted_at),
      PortfolioItem.active.where(status: "pending_review").minimum(:submitted_at),
      VerificationRequest.where(status: "pending_review").minimum(:submitted_at)
    ].compact
    {
      pending_count: pending_count,
      reviewed_today_count: ModerationAction.where(action: %w[approved rejected], created_at: Time.current.all_day).count,
      oldest_pending_submitted_at: pending_times.min
    }
  end

  def pending_count
    ProfessionalProfileRevision.where(status: "pending_review").count +
      ProfessionalProfilePhoto.where(status: "pending_review").count +
      PortfolioItem.active.where(status: "pending_review").count +
      VerificationRequest.where(status: "pending_review").count
  end
end
