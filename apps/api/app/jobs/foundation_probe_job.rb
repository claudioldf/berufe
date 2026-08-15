# frozen_string_literal: true

class FoundationProbeJob < ApplicationJob
  class ProbeFailure < StandardError; end

  queue_as :default
  retry_on ProbeFailure, wait: 1.second, attempts: 2

  def perform(probe_id:, fail_once: false)
    raise ProbeFailure, "requested foundation retry" if fail_once && executions < 2

    Rails.logger.info(event: "foundation_probe_completed", probe_id:, correlation_id:)
  end
end
