# frozen_string_literal: true

class ProfessionalCustomerCandidateQuery
  MAXIMUM_QUERY_LENGTH = 80
  LIMIT = 10

  class Invalid < StandardError
    attr_reader :field_errors

    def initialize(field_errors)
      @field_errors = field_errors
      super("invalid professional customer candidate query")
    end
  end

  def call(professional:, query:)
    normalized = query.to_s.squish
    return Customer.none if normalized.length < 2
    raise Invalid.new(query: ["deve ter no máximo 80 caracteres"]) if normalized.length > MAXIMUM_QUERY_LENGTH

    pattern = "%#{ActiveRecord::Base.sanitize_sql_like(normalized)}%"
    professional.customers
      .where("name ILIKE ?", pattern)
      .order(Arel.sql("name ASC"), id: :asc)
      .limit(LIMIT)
  end
end
