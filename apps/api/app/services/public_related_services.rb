# frozen_string_literal: true

class PublicRelatedServices
  LIMIT = 3

  def call(normalized_term:, active_services:, resolved_service: nil)
    candidates = active_services.reject { |service| service.id == resolved_service&.id }
    candidates.sort_by do |service|
      [category_priority(service, resolved_service), service_distance(service, normalized_term), service.sort_order, service.slug]
    end.first(LIMIT)
  end

  private

  def category_priority(service, resolved_service)
    return 0 unless resolved_service

    (service.category_id == resolved_service.category_id) ? 0 : 1
  end

  def service_distance(service, normalized_term)
    values = [service.slug, service.name, *service.aliases].map { |value| PublicSearchText.normalize(value) }
    values.filter_map do |value|
      next if normalized_term.blank?

      levenshtein(value, normalized_term)
    end.min || 0
  end

  def levenshtein(left, right)
    previous = (0..right.length).to_a
    left.each_char.with_index(1) do |left_character, row|
      current = [row]
      right.each_char.with_index(1) do |right_character, column|
        insertion = current[column - 1] + 1
        deletion = previous[column] + 1
        substitution = previous[column - 1] + ((left_character == right_character) ? 0 : 1)
        current << [insertion, deletion, substitution].min
      end
      previous = current
    end
    previous.last
  end
end
