# frozen_string_literal: true

class ProfessionalCoverageSerializer
  def initialize(revision)
    @revision = revision
  end

  def as_json(*)
    {
      city: revision.coverage_city && LocationSerializer.city(revision.coverage_city),
      whole_city: revision.covers_whole_city?,
      neighborhoods: revision.professional_profile_service_areas
        .filter_map(&:neighborhood)
        .sort_by { |neighborhood| [neighborhood.name, neighborhood.code] }
        .map { |neighborhood| LocationSerializer.neighborhood(neighborhood).slice(:code, :name) }
    }
  end

  private

  attr_reader :revision
end
