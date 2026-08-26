# frozen_string_literal: true

require Rails.root.join("lib/berufe/reporting")

module Admin
  class SearchAuditIndexQuery
    DEFAULT_PER_PAGE = 20
    MAX_PER_PAGE = 100
    MAX_QUERY_LENGTH = 100
    OUTCOMES = %w[
      zero_results
      not_understood
      thin_results
      operational_issue
      healthy
    ].freeze
    DEFAULT_SORT = "results_asc"
    SORTS = %w[results_asc gaps newest results_desc].freeze
    OPERATIONAL_STATUSES = %w[
      processing
      application_rate_limited
      provider_rate_limited
      provider_unavailable
      search_failed
    ].freeze

    Result = Data.define(:events, :page, :per_page, :total_count, :summary) do
      def total_pages
        total_count.zero? ? 0 : (total_count.to_f / per_page).ceil
      end
    end

    class Invalid < StandardError
      attr_reader :field_errors

      def initialize(field_errors)
        @field_errors = field_errors
        super("invalid administrator search-audit query")
      end
    end

    def initialize(now: -> { Time.current })
      @now = now
    end

    def call(page: 1, per_page: DEFAULT_PER_PAGE, q: nil, outcome: nil, sort: DEFAULT_SORT)
      normalized_page, normalized_per_page, pagination_errors = normalize_pagination(page:, per_page:)
      normalized_query, normalized_outcome, normalized_sort, filter_errors = normalize_filters(q:, outcome:, sort:)
      errors = pagination_errors.merge(filter_errors)
      raise Invalid, errors if errors.any?

      current_time = now.call
      scope = SearchEvent.llm_audits.where(created_at: audit_window_start(current_time)..current_time)
      searched_scope = apply_query(scope, normalized_query)
      summary = summarize(searched_scope)
      filtered_scope = apply_outcome(searched_scope, normalized_outcome)
      total_count = filtered_scope.count
      events = apply_sort(filtered_scope, normalized_sort)
        .limit(normalized_per_page)
        .offset((normalized_page - 1) * normalized_per_page)

      Result.new(events:, page: normalized_page, per_page: normalized_per_page, total_count:, summary:)
    end

    private

    attr_reader :now

    def audit_window_start(current_time)
      Berufe::Reporting.llm_search_audit_window_start(current_time)
    end

    def normalize_filters(q:, outcome:, sort:)
      errors = {}
      normalized_query = if q.nil? || q == ""
        nil
      elsif q.is_a?(String)
        q.squish.presence
      else
        errors[:q] = ["deve ser um texto"]
      end
      if normalized_query&.length.to_i > MAX_QUERY_LENGTH
        errors[:q] = ["deve ter no máximo #{MAX_QUERY_LENGTH} caracteres"]
      end

      normalized_outcome = outcome.to_s.presence
      unless normalized_outcome.nil? || OUTCOMES.include?(normalized_outcome)
        errors[:outcome] = ["use um dos valores: #{OUTCOMES.join(", ")}"]
      end
      normalized_sort = sort.to_s.presence || DEFAULT_SORT
      unless SORTS.include?(normalized_sort)
        errors[:sort] = ["use um dos valores: #{SORTS.join(", ")}"]
      end
      [normalized_query, normalized_outcome, normalized_sort, errors]
    end

    def apply_query(scope, query)
      return scope unless query

      pattern = "%#{ActiveRecord::Base.sanitize_sql_like(query.downcase)}%"
      scope.where(<<~SQL.squish, pattern:)
        LOWER(search_events.input_prompt) LIKE :pattern
        OR LOWER(COALESCE(search_events.parsed_response ->> 'normalized_request', '')) LIKE :pattern
        OR EXISTS (
          SELECT 1
          FROM jsonb_array_elements(COALESCE(search_events.parsed_response -> 'services', '[]'::jsonb)) service
          WHERE LOWER(COALESCE(service ->> 'name', '')) LIKE :pattern
        )
        OR EXISTS (
          SELECT 1
          FROM jsonb_array_elements(COALESCE(search_events.parsed_response -> 'locations', '[]'::jsonb)) location
          WHERE LOWER(COALESCE(location ->> 'city', '')) LIKE :pattern
             OR LOWER(COALESCE(location -> 'neighborhood' ->> 'name', '')) LIKE :pattern
        )
      SQL
    end

    def apply_outcome(scope, outcome)
      case outcome
      when "zero_results"
        scope.where(audit_status: "completed", result_count: 0)
      when "not_understood"
        scope.where(audit_status: "response_rejected")
      when "thin_results"
        scope.where(audit_status: "completed", result_count: 1..2)
      when "operational_issue"
        scope.where(audit_status: OPERATIONAL_STATUSES)
      when "healthy"
        scope.where(audit_status: "completed").where("result_count >= 3")
      else
        scope
      end
    end

    def summarize(scope)
      counts = scope.pick(
        Arel.sql("COUNT(*)"),
        Arel.sql("COUNT(*) FILTER (WHERE audit_status = 'completed' AND result_count = 0)"),
        Arel.sql("COUNT(*) FILTER (WHERE audit_status = 'response_rejected')"),
        Arel.sql("COUNT(*) FILTER (WHERE audit_status = 'completed' AND result_count BETWEEN 1 AND 2)"),
        Arel.sql(<<~SQL.squish),
          COUNT(*) FILTER (
            WHERE audit_status IN (
              'processing', 'application_rate_limited', 'provider_rate_limited',
              'provider_unavailable', 'search_failed'
            )
          )
        SQL
        Arel.sql("COUNT(*) FILTER (WHERE audit_status = 'completed' AND result_count >= 3)")
      )
      %i[total zero_results not_understood thin_results operational_issue healthy]
        .zip(counts)
        .to_h
    end

    def apply_sort(scope, sort)
      case sort
      when "results_asc"
        scope.order(result_count: :asc, created_at: :desc, id: :desc)
      when "newest"
        scope.order(created_at: :desc, id: :desc)
      when "results_desc"
        scope.order(result_count: :desc, created_at: :desc, id: :desc)
      else
        scope.order(Arel.sql(<<~SQL.squish), created_at: :desc, id: :desc)
          CASE
            WHEN audit_status = 'completed' AND result_count = 0 THEN 0
            WHEN audit_status = 'response_rejected' THEN 1
            WHEN audit_status = 'completed' AND result_count BETWEEN 1 AND 2 THEN 2
            WHEN audit_status IN (
              'processing', 'application_rate_limited', 'provider_rate_limited',
              'provider_unavailable', 'search_failed'
            ) THEN 3
            WHEN audit_status = 'completed' AND result_count >= 3 THEN 4
            ELSE 5
          END
        SQL
      end
    end

    def normalize_pagination(page:, per_page:)
      normalized_page = Integer(page.to_s.presence || 1, exception: false)
      normalized_per_page = Integer(per_page.to_s.presence || DEFAULT_PER_PAGE, exception: false)
      errors = {}
      errors[:page] = ["deve ser maior que zero"] unless normalized_page&.positive?
      unless normalized_per_page&.between?(1, MAX_PER_PAGE)
        errors[:per_page] = ["deve estar entre 1 e #{MAX_PER_PAGE}"]
      end
      [normalized_page, normalized_per_page, errors]
    end
  end
end
