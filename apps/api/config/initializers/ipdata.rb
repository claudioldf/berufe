# frozen_string_literal: true

# Built in to_prepare so IpdataClient (an app/ constant) is autoloadable here.
Rails.application.config.to_prepare do
  api_key = ENV["IPDATA_API_KEY"].to_s.strip

  Rails.application.config.x.berufe.ipdata_client = IpdataClient.new(api_key:, timeout: 2) if api_key.present?

  Rails.application.config.x.berufe.ip_location_cache = ActiveSupport::Cache::MemoryStore.new(
    size: 4.megabytes
  )
end
