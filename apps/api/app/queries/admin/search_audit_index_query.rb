# frozen_string_literal: true

module Admin
  class SearchAuditIndexQuery
    DEFAULT_PER_PAGE = 20
    MAX_PER_PAGE = 100

    Result = Data.define(:events, :page, :per_page, :total_count) do
      def total_pages
        total_count.zero? ? 0 : (total_count.to_f / per_page).ceil
      end
    end

    class Invalid < StandardError
      attr_reader :field_errors

      def initialize(field_errors)
        @field_errors = field_errors
        super("invalid administrator search-audit pagination")
      end
    end

    def initialize(now: -> { Time.current })
      @now = now
    end

    def call(page: 1, per_page: DEFAULT_PER_PAGE)
      normalized_page, normalized_per_page = normalize_pagination(page:, per_page:)
      current_time = now.call
      scope = SearchEvent.llm_audits.where(created_at: audit_window_start(current_time)..current_time)
      total_count = scope.count
      events = scope
        .order(created_at: :desc, id: :desc)
        .limit(normalized_per_page)
        .offset((normalized_page - 1) * normalized_per_page)

      Result.new(events:, page: normalized_page, per_page: normalized_per_page, total_count:)
    end

    private

    attr_reader :now

    def audit_window_start(current_time)
      current_time - Rails.configuration.x.berufe.reporting.llm_search_audit_retention_days.days
    end

    def normalize_pagination(page:, per_page:)
      normalized_page = Integer(page.to_s.presence || 1, exception: false)
      normalized_per_page = Integer(per_page.to_s.presence || DEFAULT_PER_PAGE, exception: false)
      errors = {}
      errors[:page] = ["deve ser maior que zero"] unless normalized_page&.positive?
      unless normalized_per_page&.between?(1, MAX_PER_PAGE)
        errors[:per_page] = ["deve estar entre 1 e #{MAX_PER_PAGE}"]
      end
      raise Invalid, errors if errors.any?

      [normalized_page, normalized_per_page]
    end
  end
end
