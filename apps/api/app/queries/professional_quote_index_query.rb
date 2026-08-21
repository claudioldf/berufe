# frozen_string_literal: true

class ProfessionalQuoteIndexQuery
  DEFAULT_PER_PAGE = 20
  MAX_PER_PAGE = 100
  MAX_SEARCH_LENGTH = 100
  STATUSES = ["all", *Quote::STATUSES].freeze
  SORTS = %w[number customer total status updated].freeze
  DIRECTIONS = %w[asc desc].freeze
  UUID_PATTERN = /\A[0-9a-f]{8}-(?:[0-9a-f]{4}-){3}[0-9a-f]{12}\z/i
  SORT_ATTRIBUTES = {
    "number" => :quote_number,
    "customer" => :customer_name,
    "total" => :total_amount,
    "status" => :status,
    "updated" => :updated_at
  }.freeze
  NORMALIZED_SEARCH_SQL = <<~SQL.squish.freeze
    translate(
      lower(concat_ws(' ', quotes.quote_number::text, quotes.customer_name, quotes.service_description)),
      'áàâãäéèêëíìîïóòôõöúùûüç',
      'aaaaaeeeeiiiiooooouuuuc'
    ) LIKE :pattern
  SQL

  Result = Data.define(:quotes, :page, :per_page, :total_count) do
    def total_pages
      total_count.zero? ? 0 : (total_count.to_f / per_page).ceil
    end

    def meta
      {page:, per_page:, total_count:, total_pages:}
    end
  end

  class Invalid < StandardError
    attr_reader :field_errors

    def initialize(field_errors)
      @field_errors = field_errors
      super("invalid professional quote index filters")
    end
  end

  def call(
    scope:,
    search: nil,
    status: "all",
    scheduled_on: nil,
    customer_id: nil,
    sort: "updated",
    direction: "desc",
    page: 1,
    per_page: DEFAULT_PER_PAGE
  )
    filters = normalize_filters(
      search:,
      status:,
      scheduled_on:,
      customer_id:,
      sort:,
      direction:,
      page:,
      per_page:
    )
    filtered = filter(scope, filters)
    total_count = filtered.count(:id)
    quotes = order(filtered, filters)
      .limit(filters[:per_page])
      .offset((filters[:page] - 1) * filters[:per_page])

    Result.new(
      quotes:,
      page: filters[:page],
      per_page: filters[:per_page],
      total_count:
    )
  end

  private

  def normalize_filters(search:, status:, scheduled_on:, customer_id:, sort:, direction:, page:, per_page:)
    normalized_search = search.to_s.strip
    normalized_status = status.to_s.presence || "all"
    normalized_sort = sort.to_s.presence || "updated"
    normalized_direction = direction.to_s.presence || "desc"
    normalized_page = Integer(page.to_s.presence || 1, exception: false)
    normalized_per_page = Integer(per_page.to_s.presence || DEFAULT_PER_PAGE, exception: false)
    normalized_scheduled_on = normalize_date(scheduled_on)
    normalized_customer_id = customer_id.to_s.strip.presence
    errors = {}

    if normalized_search.length > MAX_SEARCH_LENGTH
      errors[:search] = ["use uma busca com até #{MAX_SEARCH_LENGTH} caracteres"]
    end
    errors[:status] = ["use um status de orçamento válido"] unless STATUSES.include?(normalized_status)
    errors[:scheduled_on] = ["use uma data válida"] if scheduled_on.present? && normalized_scheduled_on.nil?
    if normalized_customer_id && !UUID_PATTERN.match?(normalized_customer_id)
      errors[:customer_id] = ["use um cliente válido"]
    end
    errors[:sort] = ["use uma coluna de ordenação válida"] unless SORTS.include?(normalized_sort)
    errors[:direction] = ["use asc ou desc"] unless DIRECTIONS.include?(normalized_direction)
    errors[:page] = ["deve ser maior que zero"] unless normalized_page&.positive?
    unless normalized_per_page&.between?(1, MAX_PER_PAGE)
      errors[:per_page] = ["deve estar entre 1 e #{MAX_PER_PAGE}"]
    end
    raise Invalid, errors if errors.any?

    {
      search: normalize_search(normalized_search),
      status: normalized_status,
      scheduled_on: normalized_scheduled_on,
      customer_id: normalized_customer_id,
      sort: normalized_sort,
      direction: normalized_direction,
      page: normalized_page,
      per_page: normalized_per_page
    }
  end

  def normalize_date(value)
    return if value.blank?

    Date.iso8601(value.to_s)
  rescue Date::Error
    nil
  end

  def normalize_search(value)
    ActiveSupport::Inflector.transliterate(value).downcase.delete_prefix("#").strip
  end

  def filter(scope, filters)
    filtered = scope
    filtered = filtered.where(status: filters[:status]) unless filters[:status] == "all"
    filtered = filtered.where(scheduled_on: filters[:scheduled_on]) if filters[:scheduled_on]
    filtered = filtered.where(customer_id: filters[:customer_id]) if filters[:customer_id]
    return filtered if filters[:search].blank?

    pattern = "%#{ActiveRecord::Base.sanitize_sql_like(filters[:search])}%"
    filtered.where(NORMALIZED_SEARCH_SQL, pattern:)
  end

  def order(scope, filters)
    table = Quote.arel_table
    attribute = table[SORT_ATTRIBUTES.fetch(filters[:sort])]
    attribute = Arel::Nodes::NamedFunction.new("LOWER", [attribute]) if filters[:sort] == "customer"
    primary = (filters[:direction] == "asc") ? attribute.asc : attribute.desc
    tie_breaker = (filters[:direction] == "asc") ? table[:id].asc : table[:id].desc
    scope.order(primary, tie_breaker)
  end
end
