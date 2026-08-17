# frozen_string_literal: true

class PublicProfessionalSearch
  MAXIMUM_TERM_LENGTH = 80
  ALL_JOINVILLE = "all"

  Result = Data.define(
    :normalized_term,
    :service,
    :neighborhood,
    :professionals,
    :related_services
  )

  class InvalidInput < StandardError
    attr_reader :field_errors

    def initialize(field_errors)
      @field_errors = field_errors
      super("invalid public professional search")
    end
  end

  def initialize(resolver: PublicServiceResolver.new, related_services: PublicRelatedServices.new)
    @resolver = resolver
    @related_services = related_services
  end

  def call(term:, neighborhood_code: nil)
    validate_term!(term)
    resolution = resolver.call(term)
    validate_normalized_term!(resolution.normalized_term)
    neighborhood = resolve_neighborhood(neighborhood_code)

    professionals = resolution.service ? matching_professionals(resolution.service, neighborhood) : ProfessionalProfile.none
    suggestions = related_services.call(
      normalized_term: resolution.normalized_term,
      active_services: resolution.active_services,
      resolved_service: resolution.service
    )

    Result.new(
      normalized_term: resolution.normalized_term,
      service: resolution.service,
      neighborhood:,
      professionals:,
      related_services: suggestions
    )
  end

  private

  attr_reader :resolver, :related_services

  def validate_term!(term)
    return if term.is_a?(String) && term.length <= MAXIMUM_TERM_LENGTH

    raise InvalidInput, {service: ["deve ter no máximo 80 caracteres"]}
  end

  def validate_normalized_term!(normalized_term)
    return if normalized_term.present?

    raise InvalidInput, {service: ["é obrigatório"]}
  end

  def resolve_neighborhood(neighborhood_code)
    code = neighborhood_code.to_s.strip
    return if code.blank? || code == ALL_JOINVILLE

    Neighborhood.active.find_by(code:) || raise(
      InvalidInput,
      {neighborhoodCode: ["não é um bairro ativo de Joinville"]}
    )
  end

  def matching_professionals(service, neighborhood)
    relation = ProfessionalProfile
      .publicly_eligible
      .joins(published_revision: :professional_profile_services)
      .where(professional_profile_services: {service_id: service.id})
    relation = relation.where(coverage_sql, neighborhood.code) if neighborhood
    relation
      .includes(
        :published_photo,
        :verification_requests,
        :portfolio_items,
        published_revision: {
          professional_profile_services: :service,
          professional_profile_service_areas: :neighborhood
        }
      )
      .order(*ranking_order(neighborhood))
  end

  def ranking_order(neighborhood)
    [
      explicit_neighborhood_order(neighborhood),
      approved_identity_order,
      approved_portfolio_order,
      public_relationship_order,
      Arel.sql("professional_profile_revisions.reviewed_at DESC NULLS LAST"),
      Arel.sql("professional_profiles.id ASC")
    ].compact
  end

  def explicit_neighborhood_order(neighborhood)
    return unless neighborhood

    quoted_code = ActiveRecord::Base.connection.quote(neighborhood.code)
    Arel.sql(<<~SQL.squish)
      CASE WHEN EXISTS (
        SELECT 1
        FROM professional_profile_service_areas ranked_areas
        WHERE ranked_areas.professional_profile_revision_id = professional_profiles.published_revision_id
          AND ranked_areas.neighborhood_code = #{quoted_code}
      ) THEN 0 ELSE 1 END ASC
    SQL
  end

  def approved_identity_order
    label = ActiveRecord::Base.connection.quote(ModerationDecision::IDENTITY_LABEL)
    Arel.sql(<<~SQL.squish)
      CASE WHEN EXISTS (
        SELECT 1
        FROM verification_requests ranked_verifications
        WHERE ranked_verifications.professional_profile_id = professional_profiles.id
          AND ranked_verifications.verification_type = 'identity'
          AND ranked_verifications.status = 'approved'
          AND ranked_verifications.public_label = #{label}
          AND ranked_verifications.verified_at IS NOT NULL
      ) THEN 0 ELSE 1 END ASC
    SQL
  end

  def approved_portfolio_order
    Arel.sql(<<~SQL.squish)
      CASE WHEN EXISTS (
        SELECT 1
        FROM portfolio_items ranked_portfolio
        WHERE ranked_portfolio.professional_profile_id = professional_profiles.id
          AND ranked_portfolio.status = 'approved'
          AND ranked_portfolio.deleted_at IS NULL
      ) THEN 0 ELSE 1 END ASC
    SQL
  end

  def public_relationship_order
    public_relationship = PublicProfessionalRelationshipQuery.call
      .where(
        "professional_relationships.initiator_professional_id = professional_profiles.id OR " \
          "professional_relationships.recipient_professional_id = professional_profiles.id"
      )
      .select("1")
    Arel.sql("CASE WHEN EXISTS (#{public_relationship.to_sql}) THEN 0 ELSE 1 END ASC")
  end

  def coverage_sql
    <<~SQL.squish
      EXISTS (
        SELECT 1
        FROM professional_profile_service_areas search_areas
        WHERE search_areas.professional_profile_revision_id = professional_profiles.published_revision_id
          AND (search_areas.neighborhood_code IS NULL OR search_areas.neighborhood_code = ?)
      )
    SQL
  end
end
