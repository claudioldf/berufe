# frozen_string_literal: true

require "maxmind/geoip2"

account_id = ENV["MAXMIND_ACCOUNT_ID"].to_s.strip
license_key = ENV["MAXMIND_LICENSE_KEY"].to_s.strip

Rails.application.config.x.berufe.maxmind_client = if account_id.present? && license_key.present?
  MaxMind::GeoIP2::Client.new(
    account_id: account_id.to_i,
    license_key:,
    host: "geolite.info",
    locales: ["pt-BR", "en"],
    timeout: 2,
    pool_size: ENV.fetch("RAILS_MAX_THREADS", "5").to_i
  )
end

Rails.application.config.x.berufe.ip_location_cache = ActiveSupport::Cache::MemoryStore.new(
  size: 4.megabytes
)
