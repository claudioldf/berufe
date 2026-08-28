# frozen_string_literal: true

class SupportedSearchLocations
  Location = Data.define(:city_code, :state_code, :city, :state_slug, :city_slug)
  FALLBACK = Location.new(
    city_code: "4209102",
    state_code: LlmSearchParser::DEFAULT_STATE_CODE,
    city: LlmSearchParser::DEFAULT_CITY,
    state_slug: LlmSearchParser::DEFAULT_STATE_CODE.downcase,
    city_slug: LlmSearchParser::DEFAULT_CITY.parameterize
  )

  def all
    locations = City.includes(:state).ordered.map { |city| build(city) }
    locations << FALLBACK unless locations.any? { |location| same?(location, FALLBACK) }
    locations.uniq.sort_by { |location| [location.state_code, location.city] }
  rescue ActiveRecord::ActiveRecordError => error
    Rails.error.report(error, handled: true, severity: :warning)
    [FALLBACK]
  end

  def find(state_code:, city:)
    all.find do |location|
      PublicSearchText.normalize(location.state_code) == PublicSearchText.normalize(state_code) &&
        PublicSearchText.normalize(location.city) == PublicSearchText.normalize(city)
    end
  end

  def find_by_code(city_code:)
    all.find { |location| location.city_code == city_code.to_s }
  end

  def find_by_route(state_slug:, city_slug:)
    all.find do |location|
      location.state_slug == state_slug.to_s.downcase &&
        location.city_slug == city_slug.to_s.downcase
    end
  end

  private

  def build(city_record)
    Location.new(
      city_code: city_record.code,
      state_code: city_record.state.abbreviation,
      city: city_record.name,
      state_slug: city_record.state.abbreviation.downcase,
      city_slug: city_record.slug
    )
  end

  def same?(first, second)
    first.city_code == second.city_code
  end
end
