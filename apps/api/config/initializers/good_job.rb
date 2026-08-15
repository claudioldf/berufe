# frozen_string_literal: true

Rails.application.configure do
  if Rails.env.test?
    config.active_job.queue_adapter = :test
  else
    config.active_job.queue_adapter = :good_job
    config.good_job.execution_mode = ENV.fetch("GOOD_JOB_EXECUTION_MODE").to_sym
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
end
