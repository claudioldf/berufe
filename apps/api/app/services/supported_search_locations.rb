# frozen_string_literal: true

class SupportedSearchLocations
  Location = Data.define(:state_code, :city, :state_slug, :city_slug)
  FALLBACK = Location.new(
    state_code: LlmSearchParser::DEFAULT_STATE_CODE,
    city: LlmSearchParser::DEFAULT_CITY,
    state_slug: LlmSearchParser::DEFAULT_STATE_CODE.downcase,
    city_slug: LlmSearchParser::DEFAULT_CITY.parameterize
  )

  def all
    locations = Neighborhood.active
      .distinct
      .pluck(:state_code, :city_code)
      .map { |state_code, city| build(state_code:, city:) }
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

  def find_by_route(state_slug:, city_slug:)
    all.find do |location|
      location.state_slug == state_slug.to_s.downcase &&
        location.city_slug == city_slug.to_s.downcase
    end
  end

  private

  def build(state_code:, city:)
    Location.new(
      state_code: state_code.upcase,
      city:,
      state_slug: state_code.downcase,
      city_slug: city.parameterize
    )
  end

  def same?(first, second)
    first.state_code == second.state_code && first.city == second.city
  end
end
