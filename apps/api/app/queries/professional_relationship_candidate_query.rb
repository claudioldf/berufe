# frozen_string_literal: true

class ProfessionalRelationshipCandidateQuery
  MAXIMUM_QUERY_LENGTH = 70
  LIMIT = 10

  class Invalid < StandardError
    attr_reader :field_errors

    def initialize(field_errors)
      @field_errors = field_errors
      super("invalid professional relationship candidate query")
    end
  end

  def call(initiator:, query:)
    normalized = query.to_s.squish
    return ProfessionalProfile.none if normalized.length < 2
    raise Invalid.new(query: ["deve ter no máximo 70 caracteres"]) if normalized.length > MAXIMUM_QUERY_LENGTH

    pattern = "%#{ActiveRecord::Base.sanitize_sql_like(normalized)}%"
    ProfessionalProfile.publicly_viewable
      .joins(:published_revision)
      .where.not(id: initiator.id)
      .where("professional_profile_revisions.display_name ILIKE ?", pattern)
      .includes(:user_account, :published_photo, :published_revision)
      .order(Arel.sql("professional_profile_revisions.display_name ASC"), id: :asc)
      .limit(LIMIT)
  end
end
