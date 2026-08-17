# frozen_string_literal: true

class SearchEventQuerySanitizer
  MAX_RETAINED_WORDS = 6
  SENSITIVE_MARKERS = %r{
    @
    | https?://
    | www\.
    | \b(?:email|e-mail|telefone|celular|whats(?:app)?|cpf)\b
    | \b(?:meu\s+nome|me\s+chamo|nome\s*:|sou\s+(?:o|a))\b
    | \b[a-z0-9-]+\.[a-z]{2,}(?:\.[a-z]{2})?\b
  }ix

  def call(raw_term:, normalized_term:)
    raw = raw_term.to_s
    normalized = normalized_term.to_s
    return if normalized.blank?
    return if raw.match?(SENSITIVE_MARKERS)
    return if raw.match?(/[\r\n]/)
    return if raw.scan(/\d/).length >= 7
    return if normalized.split.length > MAX_RETAINED_WORDS

    normalized
  end
end
