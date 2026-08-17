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
  config.good_job.on_thread_error = ->(exception) { Rails.error.report(exception) }
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
    }
  }
end
