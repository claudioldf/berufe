# frozen_string_literal: true

class LocationSerializer
  class << self
    def state(state)
      {
        code: state.code,
        abbreviation: state.abbreviation,
        name: state.name
      }
    end

    def city(city)
      {
        code: city.code,
        name: city.name,
        slug: city.slug,
        state_code: city.state_code,
        state_abbreviation: city.state.abbreviation,
        state_name: city.state.name
      }
    end

    def neighborhood(neighborhood)
      {
        code: neighborhood.code,
        city_code: neighborhood.city_code,
        name: neighborhood.name
      }
    end
  end
end
