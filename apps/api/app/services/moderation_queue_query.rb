# frozen_string_literal: true

class ModerationQueueQuery
  STATUSES = %w[pending_review approved rejected all].freeze
  DEFAULT_PER_PAGE = 20
  MAX_PER_PAGE = 50

  class Invalid < StandardError
    attr_reader :field_errors

    def initialize(field_errors)
      @field_errors = field_errors
      super("invalid moderation queue filters")
    end
  end

  def call(status: "pending_review", search: nil, page: 1, per_page: DEFAULT_PER_PAGE)
    filters = normalized_filters(status:, search:, page:, per_page:)
    entries = verification_requests(filters[:status])
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

  def normalized_filters(status:, search:, page:, per_page:)
    normalized_status = status.to_s.presence || "pending_review"
    normalized_page = Integer(page.to_s.presence || 1, exception: false)
    normalized_per_page = Integer(per_page.to_s.presence || DEFAULT_PER_PAGE, exception: false)
    errors = {}
    errors[:status] = ["use um status de moderação válido"] unless STATUSES.include?(normalized_status)
    errors[:search] = ["use uma busca com até 100 caracteres"] if search.to_s.length > 100
    errors[:page] = ["deve ser maior que zero"] unless normalized_page&.positive?
    unless normalized_per_page&.between?(1, MAX_PER_PAGE)
      errors[:per_page] = ["deve estar entre 1 e #{MAX_PER_PAGE}"]
    end
    raise Invalid.new(errors) if errors.any?

    {
      status: normalized_status,
      search: normalize_search(search),
      page: normalized_page,
      per_page: normalized_per_page
    }
  end

  def verification_requests(status)
    statuses = (status == "all") ? %w[pending_review approved rejected] : [status]
    VerificationRequest.includes(:verification_file, professional_profile: :working_revision)
      .where(status: statuses)
      .map { |request_record| verification_entry(request_record) }
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
      claimed_birthdate: request_record.claimed_birthdate&.iso8601,
      verification_file_id: request_record.verification_file&.then do |file|
        file.id unless file.deleted_at?
      end
    }
  end

  def supply_subtitle(revision)
    primary = revision.professional_profile_services.includes(:service).find_by(is_primary: true)&.service&.name
    city = revision.coverage_city&.name
    [primary, city].compact_blank.join(" · ")
  end

  def search_match?(entry, search)
    return true if search.blank?

    normalize_search([entry[:target_id], entry[:title], entry[:subtitle], entry[:status]].join(" ")).include?(search)
  end

  def normalize_search(value)
    I18n.transliterate(value.to_s).downcase.squish
  end
end
