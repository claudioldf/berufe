# frozen_string_literal: true

require "json"

class LocationSeed
  DEFAULT_PATH = Rails.root.join("db/seeds/locations.json")

  def initialize(path: DEFAULT_PATH)
    @path = Pathname(path)
  end

  def call
    payload = JSON.parse(path.read, symbolize_names: true)
    Ibge::LocationImporter.new.call(
      states: payload.fetch(:states),
      cities: payload.fetch(:cities),
      neighborhoods: payload.fetch(:neighborhoods)
    )
  end

  private

  attr_reader :path
end
