# frozen_string_literal: true

# Asks the LLM for a copywritten headline/bio for a professional who hasn't
# written their own, and persists the result on the revision. Called from
# ProfessionalHeadlineBioGenerationJob, never inline from a request path —
# see PublicProfessionalProfileFallbackCopy for the always-instant read side.
class ProfessionalHeadlineBioAiGenerator
  MAXIMUM_HEADLINE_LENGTH = 120
  MAXIMUM_BIO_LENGTH = 500

  class ProviderUnavailable < StandardError; end

  RESPONSE_SCHEMA = {
    type: "object",
    additionalProperties: false,
    properties: {
      headline: {type: "string", minLength: 1, maxLength: MAXIMUM_HEADLINE_LENGTH},
      bio: {type: "string", minLength: 1, maxLength: MAXIMUM_BIO_LENGTH}
    },
    required: %w[headline bio]
  }.freeze

  def initialize(client: Llm::Client.build, settings: Rails.configuration.x.berufe.environment)
    @client = client
    @settings = settings
  end

  def call(revision:)
    display_name = revision.display_name
    city = revision.coverage_city&.name
    state_abbreviation = revision.coverage_city&.state&.abbreviation
    services = ordered_service_names(revision)
    years_experience = revision.years_experience

    prompt = ProfessionalHeadlineBioPrompt.new(display_name:, city:, state_abbreviation:, services:, years_experience:)
    response = client.generate(
      prompt: prompt.render,
      input: "Gere o headline e a bio para este profissional, seguindo estritamente as instruções acima.",
      schema: RESPONSE_SCHEMA,
      schema_name: "berufe_professional_headline_bio",
      fake_payload: fake_payload_for(city:, services:, years_experience:)
    )
    headline = clamp(response.payload["headline"], MAXIMUM_HEADLINE_LENGTH)
    bio = clamp(response.payload["bio"], MAXIMUM_BIO_LENGTH)
    return unless headline && bio

    revision.update!(
      ai_headline: headline,
      ai_bio: bio,
      ai_copy_model: settings.openai_model,
      ai_copy_generated_at: Time.current
    )
  rescue Llm::Client::Unavailable => error
    Rails.error.report(error, context: {professional_profile_revision_id: revision.id})
    raise ProviderUnavailable, error.message
  end

  private

  attr_reader :client, :settings

  def ordered_service_names(revision)
    revision.professional_profile_services
      .sort_by { |selection| [selection.is_primary? ? 0 : 1, selection.service.name, selection.id] }
      .map { |selection| selection.service.name }
  end

  def clamp(value, maximum_length)
    value.to_s.squish.truncate(maximum_length, separator: " ", omission: "…").presence
  end

  # No network call in fake/test mode: build a small deterministic payload
  # from the same inputs the real prompt would have used. This intentionally
  # does not depend on the professional's published revision, which may not
  # exist yet — these updaters also run mid-onboarding, before first publish.
  def fake_payload_for(city:, services:, years_experience:)
    primary_service = services.first
    base = if primary_service && city
      "#{primary_service} em #{city}"
    elsif primary_service
      primary_service
    elsif city
      "Profissional em #{city}"
    else
      "Perfil profissional"
    end
    headline = if years_experience.present? && years_experience.positive?
      "#{base} com #{years_experience} #{(years_experience == 1) ? "ano" : "anos"} de experiência"
    else
      base
    end
    bio = if services.any?
      location = city ? " em #{city}" : ""
      "Ofereço serviços como #{services.join(", ")}#{location}. Fale comigo para saber mais."
    else
      "Aqui você encontra mais informações sobre o meu trabalho e pode falar comigo para saber mais."
    end
    {
      "headline" => headline.truncate(MAXIMUM_HEADLINE_LENGTH),
      "bio" => bio.truncate(MAXIMUM_BIO_LENGTH)
    }
  end
end
