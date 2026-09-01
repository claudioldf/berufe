# frozen_string_literal: true

class PublicProfessionalSearch
  MAXIMUM_TERM_LENGTH = LlmSearchParser::MAXIMUM_EXPRESSION_LENGTH
  DEFAULT_PER_PAGE = 20
  MAX_PER_PAGE = 50
  UUID_PATTERN = /\A[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}\z/i

  Result = Data.define(:criteria, :services, :professionals, :related_services, :page, :per_page, :total_count) do
    def total_pages
      total_count.zero? ? 0 : (total_count.to_f / per_page).ceil
    end

    def matching_service_for(profile)
      profile_services = profile.published_revision.professional_profile_services
      service_ids.each do |service_id|
        match = profile_services.find { |profile_service| profile_service.service_id == service_id }
        return match.service if match
      end
      nil
    end

    def service_ids
      criteria.service_ids
    end

    def neighborhood_codes
      criteria.locations.filter_map(&:neighborhood_code)
    end
  end

  class InvalidInput < StandardError
    attr_reader :field_errors

    def initialize(field_errors)
      @field_errors = field_errors
      super("invalid public professional search")
    end
  end

  def initialize(parser: LlmSearchParser.new, related_services: PublicRelatedServices.new)
    @parser = parser
    @related_services = related_services
  end

  def self.normalize_pagination(page:, per_page:)
    normalized_page = Integer(page.to_s.presence || 1, exception: false)
    normalized_per_page = Integer(per_page.to_s.presence || DEFAULT_PER_PAGE, exception: false)
    errors = {}
    errors[:page] = ["deve ser maior que zero"] unless normalized_page&.positive?
    unless normalized_per_page&.between?(1, MAX_PER_PAGE)
      errors[:per_page] = ["deve estar entre 1 e #{MAX_PER_PAGE}"]
    end
    raise InvalidInput, errors if errors.any?

    [normalized_page, normalized_per_page]
  end

  def call(expression:, default_location: nil, page: 1, per_page: DEFAULT_PER_PAGE, audit_event: nil)
    normalized_page, normalized_per_page = normalize_pagination(page, per_page)
    default_location = validated_default_location(default_location)
    criteria = if audit_event
      parser.call(expression:, default_location:, audit_event:)
    else
      parser.call(expression:, default_location:)
    end
    result_for(criteria, page: normalized_page, per_page: normalized_per_page)
  rescue LlmSearchParser::InvalidExpression
    raise InvalidInput, {expression: ["é obrigatória e deve ter no máximo #{MAXIMUM_TERM_LENGTH} caracteres"]}
  rescue LlmSearchParser::LocationUnsupported
    raise InvalidInput, {expression: ["informe uma cidade brasileira reconhecida"]}
  rescue LlmSearchParser::LocationUnrecognized
    raise InvalidInput, {expression: ["informe um bairro reconhecido da cidade buscada"]}
  end

  def call_with_filters(service_id:, city_code:, page: 1, per_page: DEFAULT_PER_PAGE)
    normalized_page, normalized_per_page = normalize_pagination(page, per_page)
    service = structured_service(service_id)
    location = validate_structured_location!(city_code:)
    criteria = LlmSearchParser::Criteria.new(
      service_ids: [service.id],
      locations: [
        LlmSearchParser::Location.new(
          city_code: location.city_code,
          state_code: location.state_code,
          city: location.city,
          neighborhood_code: nil
        )
      ],
      keywords: [],
      normalized_request: nil
    )
    result_for(criteria, page: normalized_page, per_page: normalized_per_page)
  end

  private

  attr_reader :parser, :related_services

  def result_for(criteria, page:, per_page:)
    active_services = Service.publicly_active.includes(:category).ordered.to_a
    services_by_id = active_services.index_by(&:id)
    services = criteria.service_ids.filter_map { |service_id| services_by_id[service_id] }
    matches = matching_professionals(criteria)
    total_count = matches.count(:id)
    suggestions = related_services.call(
      normalized_term: "",
      active_services:,
      resolved_service: services.first,
      excluded_service_ids: criteria.service_ids
    )

    Result.new(
      criteria:,
      services:,
      professionals: page_of(matches, criteria, page, per_page),
      related_services: suggestions,
      page:,
      per_page:,
      total_count:
    )
  end

  def structured_service(value)
    service_id = value.to_s
    service = Service.publicly_active.find_by(id: service_id) if service_id.match?(UUID_PATTERN)
    return service if service

    raise InvalidInput, {service_id: ["selecione um serviço disponível"]}
  end

  def validate_structured_location!(city_code:)
    location = AvailableSearchLocations.new.all.find { |candidate| candidate.city_code == city_code.to_s }
    return location if location

    raise InvalidInput, {city_code: ["selecione uma cidade disponível"]}
  end

  def validated_default_location(value)
    attributes = value.respond_to?(:to_h) ? value.to_h.symbolize_keys : {}
    city_code = attributes[:city_code].to_s.presence || SupportedSearchLocations::FALLBACK.city_code
    location = SupportedSearchLocations.new.find_by_code(city_code:)
    return location if location

    raise InvalidInput, {default_location: ["selecione uma cidade disponível"]}
  end

  def normalize_pagination(page, per_page)
    self.class.normalize_pagination(page:, per_page:)
  end

  def matching_professionals(criteria)
    return ProfessionalProfile.none if criteria.service_ids.empty?

    relation = ProfessionalProfile
      .publicly_searchable
      .where(service_filter_sql, criteria.service_ids)
      .where(professional_profile_revisions: {coverage_city_code: criteria.locations.map(&:city_code).uniq})
    neighborhood_codes = criteria.locations.filter_map(&:neighborhood_code).uniq
    if neighborhood_codes.any? && criteria.locations.none? { |location| location.neighborhood_code.nil? }
      relation = relation.where(coverage_sql, neighborhood_codes)
    end
    relation
  end

  def page_of(relation, criteria, page, per_page)
    relation
      .includes(
        :profile_photo,
        :verification_requests,
        :portfolio_items,
        published_revision: {
          professional_profile_services: :service,
          professional_profile_service_areas: :neighborhood
        }
      )
      .order(*ranking_order(criteria))
      .limit(per_page)
      .offset((page - 1) * per_page)
  end

  def ranking_order(criteria)
    [
      external_profile_order,
      matching_service_order(criteria.service_ids),
      explicit_neighborhood_order(criteria.locations.filter_map(&:neighborhood_code).uniq),
      approved_identity_order,
      active_portfolio_order,
      public_relationship_order,
      Arel.sql("professional_profile_revisions.updated_at DESC"),
      Arel.sql("professional_profiles.id ASC")
    ].compact
  end

  def external_profile_order
    Arel.sql("CASE WHEN professional_profile_revisions.profile_type = 'external' THEN 1 ELSE 0 END ASC")
  end

  def matching_service_order(service_ids)
    return if service_ids.empty?

    profiles = ProfessionalProfile.arel_table
    ranked_services = ProfessionalProfileService.arel_table
    ranking = Arel::Nodes::Case.new
    service_ids.each_with_index do |service_id, index|
      matching_service = ProfessionalProfileService
        .select(Arel.sql("1"))
        .where(
          ranked_services[:professional_profile_revision_id]
            .eq(profiles[:published_revision_id])
            .and(ranked_services[:service_id].eq(service_id))
        )
      ranking.when(matching_service.arel.exists).then(index)
    end

    ranking.else(service_ids.length).asc
  end

  def explicit_neighborhood_order(neighborhood_codes)
    return if neighborhood_codes.empty?

    profiles = ProfessionalProfile.arel_table
    ranked_areas = ProfessionalProfileServiceArea.arel_table
    matching_area = ProfessionalProfileServiceArea
      .select(Arel.sql("1"))
      .where(
        ranked_areas[:professional_profile_revision_id]
          .eq(profiles[:published_revision_id])
          .and(ranked_areas[:neighborhood_code].in(neighborhood_codes))
      )

    Arel::Nodes::Case.new.when(matching_area.arel.exists).then(0).else(1).asc
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

  def active_portfolio_order
    Arel.sql(<<~SQL.squish)
      CASE WHEN EXISTS (
        SELECT 1
        FROM portfolio_items ranked_portfolio
        WHERE ranked_portfolio.professional_profile_id = professional_profiles.id
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
      professional_profile_revisions.covers_whole_city = TRUE OR EXISTS (
        SELECT 1
        FROM professional_profile_service_areas search_areas
        WHERE search_areas.professional_profile_revision_id = professional_profiles.published_revision_id
          AND search_areas.neighborhood_code IN (?)
      )
    SQL
  end

  def service_filter_sql
    <<~SQL.squish
      EXISTS (
        SELECT 1
        FROM professional_profile_services search_services
        WHERE search_services.professional_profile_revision_id = professional_profiles.published_revision_id
          AND search_services.service_id IN (?)
      )
    SQL
  end
end
