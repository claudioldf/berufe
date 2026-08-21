# frozen_string_literal: true

class ProfessionalCustomerIndexQuery
  DEFAULT_PER_PAGE = 20
  MAX_PER_PAGE = 100
  MAX_SEARCH_LENGTH = 100
  NORMALIZED_NAME_SQL = <<~SQL.squish.freeze
    translate(
      lower(customers.name),
      'áàâãäéèêëíìîïóòôõöúùûüç',
      'aaaaaeeeeiiiiooooouuuuc'
    )
  SQL
  NORMALIZED_SEARCH_SQL = <<~SQL.squish.freeze
    translate(
      lower(concat_ws(' ', customers.name, customers.email)),
      'áàâãäéèêëíìîïóòôõöúùûüç',
      'aaaaaeeeeiiiiooooouuuuc'
    ) LIKE :pattern
  SQL
  PHONE_SEARCH_SQL = <<~SQL.squish.freeze
    regexp_replace(customers.whatsapp_e164, '[^0-9]', '', 'g') LIKE :phone_pattern
  SQL

  Result = Data.define(:customers, :page, :per_page, :total_count) do
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
      super("invalid professional customer index filters")
    end
  end

  def call(scope:, search: nil, page: 1, per_page: DEFAULT_PER_PAGE)
    filters = normalize_filters(search:, page:, per_page:)
    filtered = filter(scope, filters[:search])
    total_count = filtered.count(:id)
    customers = filtered
      .left_joins(:quotes)
      .select(
        "customers.*",
        "COUNT(quotes.id) AS quote_count",
        "MAX(quotes.updated_at) AS last_quote_at"
      )
      .group("customers.id")
      .order(Arel.sql("#{NORMALIZED_NAME_SQL} ASC"), id: :asc)
      .limit(filters[:per_page])
      .offset((filters[:page] - 1) * filters[:per_page])

    Result.new(
      customers:,
      page: filters[:page],
      per_page: filters[:per_page],
      total_count:
    )
  end

  private

  def normalize_filters(search:, page:, per_page:)
    normalized_search = search.to_s.strip
    normalized_page = Integer(page.to_s.presence || 1, exception: false)
    normalized_per_page = Integer(per_page.to_s.presence || DEFAULT_PER_PAGE, exception: false)
    errors = {}

    if normalized_search.length > MAX_SEARCH_LENGTH
      errors[:search] = ["use uma busca com até #{MAX_SEARCH_LENGTH} caracteres"]
    end
    errors[:page] = ["deve ser maior que zero"] unless normalized_page&.positive?
    unless normalized_per_page&.between?(1, MAX_PER_PAGE)
      errors[:per_page] = ["deve estar entre 1 e #{MAX_PER_PAGE}"]
    end
    raise Invalid, errors if errors.any?

    {
      search: ActiveSupport::Inflector.transliterate(normalized_search).downcase,
      page: normalized_page,
      per_page: normalized_per_page
    }
  end

  def filter(scope, search)
    return scope if search.blank?

    pattern = "%#{ActiveRecord::Base.sanitize_sql_like(search)}%"
    phone_search = search.gsub(/\D/, "")
    return scope.where(NORMALIZED_SEARCH_SQL, pattern:) if phone_search.blank?

    phone_pattern = "%#{ActiveRecord::Base.sanitize_sql_like(phone_search)}%"
    scope.where("(#{NORMALIZED_SEARCH_SQL}) OR (#{PHONE_SEARCH_SQL})", pattern:, phone_pattern:)
  end
end
