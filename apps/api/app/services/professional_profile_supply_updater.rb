# frozen_string_literal: true

class ProfessionalProfileSupplyUpdater
  class Invalid < StandardError
    attr_reader :field_errors

    def initialize(field_errors)
      @field_errors = field_errors
      super("invalid professional services or coverage")
    end
  end

  def call(profile:, services:, coverage:)
    normalized_services = normalize_services(services)
    normalized_coverage = normalize_coverage(coverage)
    validate_services!(normalized_services)
    validate_coverage!(normalized_coverage)

    profile.with_lock do
      validate_catalog!(normalized_services, normalized_coverage)
      editor = ProfessionalProfileRevisionEditor.new
      revision = editor.call(profile:)
      replace_services!(revision, normalized_services)
      replace_coverage!(revision, normalized_coverage)
      editor.synchronize_public_revision!(profile:)
    end
    profile
  rescue ActiveRecord::RecordInvalid => error
    raise Invalid.new(error.record.errors.to_hash(true))
  rescue ActiveRecord::RecordNotUnique
    raise Invalid.new(base: ["As seleções possuem registros duplicados."])
  end

  private

  def normalize_services(services)
    Array(services).map do |entry|
      values = entry.to_h.symbolize_keys
      {
        service_id: values[:service_id].to_s,
        is_primary: values[:is_primary] == true,
        note: values[:note].to_s.squish.presence
      }
    end
  end

  def normalize_coverage(coverage)
    values = coverage.to_h.symbolize_keys
    {
      city_code: values[:city_code].to_s,
      whole_city: values[:whole_city] == true,
      neighborhood_codes: Array(values[:neighborhood_codes]).map(&:to_s).reject(&:blank?).uniq
    }
  end

  def validate_services!(services)
    errors = []
    errors << "escolha ao menos um serviço" if services.empty?
    errors << "escolha serviços sem duplicidade" if services.map { |entry| entry[:service_id] }.uniq.length != services.length
    errors << "defina exatamente um serviço principal" unless services.count { |entry| entry[:is_primary] } == 1
    errors << "use notas de especialização com até 120 caracteres" if services.any? { |entry| entry[:note]&.length.to_i > 120 }
    errors << "escolha serviços válidos" if services.any? { |entry| entry[:service_id].blank? }
    raise Invalid.new(services: errors) if errors.any?
  end

  def validate_coverage!(coverage)
    whole_city = coverage[:whole_city]
    codes = coverage[:neighborhood_codes]
    errors = []
    errors << "selecione uma cidade" if coverage[:city_code].blank?
    errors << "não combine a cidade inteira com bairros específicos" if whole_city && codes.any?
    errors << "escolha a cidade inteira ou ao menos um bairro" unless whole_city || codes.any?
    raise Invalid.new(coverage: errors) if errors.any?
  end

  def validate_catalog!(services, coverage)
    requested_service_ids = services.map { |entry| entry[:service_id] }
    active_service_ids = Service.publicly_active.where(id: requested_service_ids).pluck(:id)
    unless active_service_ids.length == requested_service_ids.length
      raise Invalid.new(services: ["escolha apenas serviços ativos do catálogo"])
    end

    city = City.find_by(code: coverage[:city_code])
    raise Invalid.new(coverage: ["selecione uma cidade disponível"]) unless city

    requested_codes = coverage[:neighborhood_codes]
    city_codes = city.neighborhoods.where(code: requested_codes).pluck(:code)
    return if city_codes.length == requested_codes.length

    raise Invalid.new(coverage: ["escolha apenas bairros da cidade selecionada"])
  end

  def replace_services!(revision, services)
    revision.professional_profile_services.delete_all
    services.each do |entry|
      revision.professional_profile_services.create!(entry)
    end
  end

  def replace_coverage!(revision, coverage)
    revision.professional_profile_service_areas.delete_all
    revision.update!(
      coverage_city_code: coverage[:city_code],
      covers_whole_city: coverage[:whole_city]
    )
    coverage[:neighborhood_codes].each do |neighborhood_code|
      revision.professional_profile_service_areas.create!(neighborhood_code:)
    end
  end
end
