# frozen_string_literal: true

require "digest"
require "json"

# The cities a search can target. The table holds every Brazilian municipality
# (~5.5k rows) and changes only when the IBGE import runs, so the locations and
# the lookups built from them are kept in a frozen, process-wide index. Each
# call revalidates the index with one aggregate query and rebuilds it only when
# the cities changed.
class SupportedSearchLocations
  Location = Data.define(:city_code, :state_code, :city, :state_slug, :city_slug)
  FALLBACK = Location.new(
    city_code: "4209102",
    state_code: LlmSearchParser::DEFAULT_STATE_CODE,
    city: LlmSearchParser::DEFAULT_CITY,
    state_slug: LlmSearchParser::DEFAULT_STATE_CODE.downcase,
    city_slug: LlmSearchParser::DEFAULT_CITY.parameterize
  )

  Index = Data.define(:locations, :by_code, :by_route, :by_name, :longest_name_words, :fingerprint) do
    def self.build(locations)
      locations = locations.uniq.sort_by { |location| [location.state_code, location.city] }.freeze
      by_code = {}
      by_route = {}
      by_name = Hash.new { |hash, key| hash[key] = [] }
      locations.each do |location|
        by_code[location.city_code] ||= location
        by_route[[location.state_slug, location.city_slug]] ||= location
        name = PublicSearchText.normalize(location.city)
        by_name[name] << location if name.present?
      end
      by_name.default_proc = nil

      new(
        locations:,
        by_code: by_code.freeze,
        by_route: by_route.freeze,
        by_name: by_name.each_value(&:freeze).freeze,
        longest_name_words: by_name.keys.map { |name| name.count(" ") + 1 }.max || 1,
        fingerprint: Digest::SHA256.hexdigest(
          JSON.generate(locations.map { |location| [location.city_code, location.city, location.state_code] })
        )
      )
    end
  end

  CACHE_LOCK = Mutex.new
  @cache = nil

  class << self
    def index
      version = current_version
      CACHE_LOCK.synchronize do
        return @cache.last if @cache&.first == version

        built = Index.build(load_locations)
        @cache = [version, built]
        built
      end
    rescue ActiveRecord::ActiveRecordError => error
      Rails.error.report(error, handled: true, severity: :warning)
      Index.build([FALLBACK])
    end

    def reset!
      CACHE_LOCK.synchronize { @cache = nil }
    end

    private

    # Deleting a city changes the count; importing or renaming one moves the
    # latest updated_at.
    def current_version
      City.pick(Arel.sql("count(*)"), Arel.sql("max(updated_at)"))
    end

    def load_locations
      locations = City.includes(:state).ordered.map do |city|
        Location.new(
          city_code: city.code,
          state_code: city.state.abbreviation,
          city: city.name,
          state_slug: city.state.abbreviation.downcase,
          city_slug: city.slug
        )
      end
      locations << FALLBACK unless locations.any? { |location| location.city_code == FALLBACK.city_code }
      locations
    end
  end

  def all
    index.locations
  end

  def fingerprint
    index.fingerprint
  end

  def find(state_code:, city:)
    matches = index.by_name.fetch(PublicSearchText.normalize(city), [])
    if state_code.to_s.squish.present?
      normalized_state = PublicSearchText.normalize(state_code)
      matches = matches.select { |location| PublicSearchText.normalize(location.state_code) == normalized_state }
    end

    (matches.size == 1) ? matches.first : nil
  end

  def find_by_code(city_code:)
    index.by_code[city_code.to_s]
  end

  def find_by_route(state_slug:, city_slug:)
    index.by_route[[state_slug.to_s.downcase, city_slug.to_s.downcase]]
  end

  # Cities whose name appears in the text as whole words, as
  # [location, normalized_name] pairs. Looks up each run of consecutive words
  # instead of scanning every city name.
  def named_in(expression)
    words = PublicSearchText.normalize(expression).split
    names = (0...words.size).flat_map do |start|
      (1..[index.longest_name_words, words.size - start].min).map { |length| words[start, length].join(" ") }
    end

    names.uniq.flat_map do |name|
      index.by_name.fetch(name, []).map { |location| [location, name] }
    end
  end

  private

  def index
    self.class.index
  end
end
