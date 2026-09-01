# frozen_string_literal: true

class PublicProfessionalProfileFallbackCopy
  Result = Data.define(:headline, :bio)
  SUMMARY_LIMIT = 3
  MAXIMUM_HEADLINE_LENGTH = 120

  def self.call(profile:)
    new.call(profile:)
  end

  def call(profile:)
    @profile = profile
    @revision = profile.published_revision

    Result.new(
      headline: revision.headline.presence || fallback_headline,
      bio: revision.bio.presence || fallback_bio
    )
  end

  private

  attr_reader :profile, :revision

  def fallback_headline
    service = ordered_service_selections.first&.service&.name
    city = revision.coverage_city&.name
    headline = if service.present? && city.present?
      "#{service} em #{city}"
    elsif service.present?
      service
    elsif city.present?
      "Profissional em #{city}"
    else
      "Perfil profissional"
    end

    headline.truncate(MAXIMUM_HEADLINE_LENGTH, separator: " ", omission: "…")
  end

  def fallback_bio
    sections = [
      services_section,
      coverage_section,
      experience_section,
      portfolio_section
    ].compact

    sections.join(" ").presence || "Veja as informações profissionais disponíveis neste perfil."
  end

  def services_section
    names = ordered_service_selections.map { |selection| selection.service.name }
    return if names.empty?

    "Serviços informados: #{summarized_list(names, remainder: "serviço")}."
  end

  def coverage_section
    city = revision.coverage_city&.name
    return unless city
    return "Atendimento em toda a cidade de #{city}." if revision.covers_whole_city?

    neighborhoods = revision.professional_profile_service_areas
      .filter_map(&:neighborhood)
      .sort_by { |neighborhood| [neighborhood.name, neighborhood.code] }
      .map(&:name)
    return "Área de atendimento: #{city}." if neighborhoods.empty?

    label = (neighborhoods.one? ? "bairro" : "bairros")
    "Área de atendimento: #{label} #{summarized_list(neighborhoods, remainder: "bairro")}, em #{city}."
  end

  def experience_section
    years = revision.years_experience
    return if years.nil?
    return "Experiência declarada: menos de 1 ano." if years.zero?

    unit = (years == 1) ? "ano" : "anos"
    "Experiência declarada: #{years} #{unit}."
  end

  def portfolio_section
    items = public_portfolio_items
    return if items.empty?

    titles = items.first(SUMMARY_LIMIT).map { |item| "“#{item.title}”" }
    if items.one?
      "Portfólio com 1 trabalho publicado: #{titles.first}."
    else
      "Portfólio com #{items.length} trabalhos publicados, incluindo #{sentence_list(titles)}."
    end
  end

  def ordered_service_selections
    @ordered_service_selections ||= revision.professional_profile_services.sort_by do |selection|
      [selection.is_primary? ? 0 : 1, selection.service.name, selection.id]
    end
  end

  def public_portfolio_items
    return [] if profile.external_presentation?

    profile.portfolio_items
      .reject { |item| item.deleted_at.present? }
      .sort_by { |item| [-item.submitted_at.to_f, item.id] }
  end

  def summarized_list(values, remainder:)
    shown = values.first(SUMMARY_LIMIT)
    omitted_count = values.length - shown.length
    return sentence_list(shown) if omitted_count.zero?

    "#{shown.join(", ")} e mais #{omitted_count} #{remainder.pluralize(omitted_count)}"
  end

  def sentence_list(values)
    return values.first if values.one?

    [values[0...-1].join(", "), values.last].join(" e ")
  end
end
