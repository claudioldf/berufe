# frozen_string_literal: true

module Berufe
  class BugsnagHandledErrorSubscriber
    SEVERITIES = {
      info: "info",
      warning: "warning",
      error: "error"
    }.freeze

    def report(error, handled:, severity:, context:, source: nil)
      return unless handled

      Bugsnag.notify(error) do |event|
        event.severity = SEVERITIES.fetch(severity.to_sym, "warning")
        event.unhandled = false
      end
    rescue => reporter_error
      Rails.logger.error("bugsnag_handled_error_report_failed class=#{reporter_error.class}")
    end
  end
end
