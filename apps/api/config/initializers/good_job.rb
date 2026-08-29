# frozen_string_literal: true

Rails.application.configure do
  if Rails.env.test?
    config.active_job.queue_adapter = :test
  else
    config.active_job.queue_adapter = :good_job
    config.good_job.execution_mode = ENV.fetch("GOOD_JOB_EXECUTION_MODE").to_sym
    config.good_job.enable_cron = true
  end

  config.good_job.queues = ENV.fetch("GOOD_JOB_QUEUES", "default")
  config.good_job.max_threads = ENV.fetch("GOOD_JOB_MAX_THREADS", "2").to_i
  config.good_job.shutdown_timeout = 25
  config.good_job.preserve_job_records = true
  config.good_job.retry_on_unhandled_error = false
  config.good_job.cleanup_preserved_jobs_before_seconds_ago = 14.days.to_i
  config.good_job.cleanup_discarded_jobs = false
  config.good_job.dequeue_query_sort = :scheduled_at
  config.good_job.on_thread_error = lambda do |exception|
    Rails.error.report(exception, handled: false, severity: :error)
    if defined?(Bugsnag) && Bugsnag.configuration.api_key.present?
      Bugsnag.notify(exception) do |event|
        event.severity = "error"
        event.unhandled = true
      end
    end
  end
  config.good_job.cron = {
    authentication_records_cleanup: {
      cron: "17 * * * *",
      class: "AuthenticationRecordsCleanupJob",
      description: "Purge expired OTP and application-session records"
    },
    media_upload_authorization_cleanup: {
      cron: "*/10 * * * *",
      class: "MediaUploadAuthorizationCleanupJob",
      description: "Expire abandoned private media upload authorizations"
    },
    verification_file_retention_cleanup: {
      cron: "43 3 * * *",
      class: "VerificationFileRetentionCleanupJob",
      description: "Delete identity evidence thirty days after a decision"
    },
    media_retention_cleanup: {
      cron: "7 3 * * *",
      class: "MediaRetentionCleanupJob",
      description: "Delete rejected, replaced, removed, and unattached media after thirty days"
    },
    search_reporting_retention: {
      cron: "17 4 * * *",
      class: "SearchReportingRetentionJob",
      description: "Roll up anonymous search events and enforce report retention"
    },
    customer_recommendation_retention_cleanup: {
      cron: "13 3 * * *",
      class: "CustomerRecommendationRetentionCleanupJob",
      description: "Expire recommendation invitations and remove operational records after thirty days"
    },
    data_erasure_recovery: {
      cron: "*/10 * * * *",
      class: "DataErasureRecoveryJob",
      description: "Recover professional erasure requests that still need processing"
    },
    lgpd_audit_retention_cleanup: {
      cron: "29 4 * * *",
      class: "LgpdAuditRetentionCleanupJob",
      description: "Remove pseudonymized LGPD records after their five-year retention period"
    }
  }
end
