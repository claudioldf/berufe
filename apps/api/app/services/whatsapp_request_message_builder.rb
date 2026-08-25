# frozen_string_literal: true

class WhatsappRequestMessageBuilder
  MAXIMUM_REQUEST_LENGTH = 240
  SEARCH_MESSAGE = "Olá, %{professional_name}! Encontrei seu perfil na Berufe. %{request}"
  SERVICE_MESSAGE = "Olá! Vi seu perfil na Berufe para %{service}."
  GENERIC_MESSAGE = "Olá! Vi seu perfil na Berufe."
  SENSITIVE_MARKERS = %r{
    @
    | https?://
    | www\.
    | \b(?:email|e-mail|telefone|celular|whats(?:app)?|cpf)\b
    | \b(?:meu\s+nome|me\s+chamo|nome\s*:|sou\s+(?:o|a))\b
    | \b(?:rua|avenida|av\.?|travessa|alameda|rodovia)\b.{0,50}\d
    | \b[a-z0-9-]+\.[a-z]{2,}(?:\.[a-z]{2})?\b
  }ix
  DUPLICATED_CONTEXT_MARKERS = /\A(?:olá|ola|oi|bom\s+dia|boa\s+(?:tarde|noite))\b|\bberufe\b/i

  def self.call(**options)
    new.call(**options)
  end

  def self.normalize_request(value)
    new.normalize_request(value)
  end

  def call(
    professional_name:,
    service_name: nil,
    state_code: nil,
    city: nil,
    normalized_request: nil,
    search_context: false
  )
    return legacy_message(service_name) unless search_context

    request = normalize_request(normalized_request) || structured_request(
      service_name:,
      state_code:,
      city:
    )
    return legacy_message(service_name) unless request

    format(
      SEARCH_MESSAGE,
      professional_name: professional_name.to_s.squish,
      request:
    )
  end

  def normalize_request(value)
    raw = value.to_s
    normalized = raw.squish
    return if normalized.blank? || normalized.length > MAXIMUM_REQUEST_LENGTH
    return unless normalized.match?(/\AEu preciso\b/i)
    return if raw.match?(/[\r\n]/)
    return if raw.match?(SENSITIVE_MARKERS)
    return if raw.match?(DUPLICATED_CONTEXT_MARKERS)
    return if raw.scan(/\d/).length >= 7

    normalized
  end

  private

  def structured_request(service_name:, state_code:, city:)
    service = service_name.to_s.squish.presence
    return unless service

    location = [city.to_s.squish.presence, state_code.to_s.squish.presence].compact.join(", ")
    "Eu preciso de #{service.downcase}#{" em #{location}" if location.present?}."
  end

  def legacy_message(service_name)
    service = service_name.to_s.squish.presence
    return GENERIC_MESSAGE unless service

    format(SERVICE_MESSAGE, service:)
  end
end
