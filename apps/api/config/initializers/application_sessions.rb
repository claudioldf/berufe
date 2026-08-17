# frozen_string_literal: true

begin
  environment_name = "SESSION_ACTIVITY_WRITE_INTERVAL_SECONDS"
  session_activity_write_interval = Integer(ENV.fetch(environment_name, "300"), 10)
  raise ArgumentError unless session_activity_write_interval.positive?

  Rails.application.config.x.berufe.session_activity_write_interval_seconds = session_activity_write_interval
rescue ArgumentError
  raise ArgumentError, "#{environment_name} must be a positive integer"
end
