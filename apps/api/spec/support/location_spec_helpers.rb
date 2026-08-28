# frozen_string_literal: true

module LocationSpecHelpers
  def self.seed_baseline!
    state = State.find_or_create_by!(code: "42") do |record|
      record.abbreviation = "SC"
      record.name = "Santa Catarina"
    end
    City.find_or_create_by!(code: "4209102") do |city|
      city.state = state
      city.name = "Joinville"
      city.slug = "joinville"
    end
  end

  def santa_catarina_state
    State.find_or_create_by!(code: "42") do |state|
      state.abbreviation = "SC"
      state.name = "Santa Catarina"
    end
  end

  def parana_state
    State.find_or_create_by!(code: "41") do |state|
      state.abbreviation = "PR"
      state.name = "Paraná"
    end
  end

  def joinville_city
    City.find_or_create_by!(code: "4209102") do |city|
      city.state = santa_catarina_state
      city.name = "Joinville"
      city.slug = "joinville"
    end
  end

  def curitiba_city
    City.find_or_create_by!(code: "4106902") do |city|
      city.state = parana_state
      city.name = "Curitiba"
      city.slug = "curitiba"
    end
  end

  def create_location_neighborhood(code: "4209102001", name: "América", city: joinville_city)
    Neighborhood.find_or_create_by!(code:) do |neighborhood|
      neighborhood.city = city
      neighborhood.name = name
    end
  end
end
