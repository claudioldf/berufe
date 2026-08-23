# frozen_string_literal: true

require Rails.root.join("lib/berufe/bugsnag_privacy")

if ENV["BUGSNAG_API_KEY"].present?
  Bugsnag.configure do |config|
    config.api_key = ENV.fetch("BUGSNAG_API_KEY")
    config.app_version = ENV["RAILWAY_GIT_COMMIT_SHA"].presence
    config.auto_track_sessions = false
    config.enabled_breadcrumb_types = []
    config.enabled_release_stages = %w[production]
    config.release_stage = ENV.fetch("BERUFE_ENV", Rails.env)
    config.send_environment = false
    config.redacted_keys += Berufe::BugsnagPrivacy::REDACTED_KEYS
    config.add_on_error(Berufe::BugsnagPrivacy)
  end
end
