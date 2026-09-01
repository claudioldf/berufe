# frozen_string_literal: true

class PublicProfessionalProfileFallbackCopy
  Result = Data.define(:headline, :bio)
  SUMMARY_LIMIT = 3
  MAXIMUM_HEADLINE_LENGTH = 120
  MAXIMUM_BIO_LENGTH = 2500

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
    base = if service.present? && city.present?
      "#{service} em #{city}"
    elsif service.present?
      service
    elsif city.present?
      "Profissional em #{city}"
    else
      "Perfil profissional"
    end

    candidates = []
    candidates << "#{base} com #{experience_length}" if experience_length
    candidates << base
    candidates << service if service.present?
    candidates << "Perfil profissional"
    candidates.find { |candidate| candidate.length <= MAXIMUM_HEADLINE_LENGTH }
  end

  def fallback_bio
    sections = [
      offering_section,
      experience_section,
      portfolio_section
    ].compact

    (sections.join(" ").presence || generic_bio)
      .truncate(MAXIMUM_BIO_LENGTH, separator: " ", omission: "…")
  end

  def offering_section
    services = service_names.map { |name| name.downcase }
    city = revision.coverage_city&.name
    neighborhoods = neighborhood_names

    if services.any?
      sentence = "#{external_profile? ? "Oferece" : "Ofereço"} serviços como " \
        "#{summarized_list(services, remainder: "serviço")}"
      sentence += if city.present? && revision.covers_whole_city?
        " em toda a cidade de #{city}"
      elsif city.present? && neighborhoods.any?
        " em #{city}, com atendimento #{neighborhood_phrase(neighborhoods)}"
      elsif city.present?
        " em #{city}"
      else
        ""
      end
      return "#{sentence}."
    end

    return unless city
    return "#{external_profile? ? "Atende" : "Atendo"} em toda a cidade de #{city}." if revision.covers_whole_city?
    return "#{external_profile? ? "Atende" : "Atendo"} em #{city}." if neighborhoods.empty?

    "#{external_profile? ? "Atende" : "Atendo"} em #{city}, #{neighborhood_phrase(neighborhoods)}."
  end

  def neighborhood_names
    @neighborhood_names ||= revision.professional_profile_service_areas
      .filter_map(&:neighborhood)
      .sort_by { |neighborhood| [neighborhood.name, neighborhood.code] }
      .map(&:name)
  end

  def neighborhood_phrase(neighborhoods)
    label = (neighborhoods.one? ? "bairro" : "bairros")
    preposition = (neighborhoods.one? ? "no" : "nos")
    "#{preposition} #{label} #{summarized_list(neighborhoods, remainder: "bairro")}"
  end

  def experience_section
    years = revision.years_experience
    return if years.nil? || years.zero?

    "#{external_profile? ? "Tem" : "Tenho"} #{experience_length} na área."
  end

  def portfolio_section
    items = public_portfolio_items
    return if items.empty?

    titles = items.first(SUMMARY_LIMIT).map { |item| "“#{item.title}”" }
    if items.one?
      "No meu portfólio, você pode conhecer o trabalho #{titles.first}."
    else
      "No meu portfólio, você pode conhecer trabalhos como #{sentence_list(titles)}."
    end
  end

  def experience_length
    years = revision.years_experience
    return if years.nil? || years.zero?

    "#{years} #{(years == 1) ? "ano" : "anos"} de experiência"
  end

  def generic_bio
    if external_profile?
      "Aqui você encontra mais informações sobre este profissional e pode entrar em contato para saber mais."
    else
      "Aqui você encontra mais informações sobre o meu trabalho e pode falar comigo para saber mais."
    end
  end

  def service_names
    @service_names ||= ordered_service_selections.map { |selection| selection.service.name }
  end

  def ordered_service_selections
    @ordered_service_selections ||= revision.professional_profile_services.sort_by do |selection|
      [selection.is_primary? ? 0 : 1, selection.service.name, selection.id]
    end
  end

  def public_portfolio_items
    return [] if external_profile?

    profile.portfolio_items
      .reject { |item| item.deleted_at.present? }
      .sort_by { |item| [-item.submitted_at.to_f, item.id] }
  end

  def external_profile?
    @external_profile ||= profile.external_presentation?
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
