# frozen_string_literal: true

class EstablishDatabaseBaseline < ActiveRecord::Migration[8.1]
  GOOD_JOB_DATETIME_COLUMNS = {
    good_jobs: %i[scheduled_at performed_at finished_at created_at updated_at locked_at cron_at],
    good_job_batches: %i[created_at updated_at enqueued_at discarded_at finished_at jobs_finished_at],
    good_job_executions: %i[created_at updated_at scheduled_at finished_at],
    good_job_processes: %i[created_at updated_at],
    good_job_settings: %i[created_at updated_at]
  }.freeze

  def up
    enable_extension "pgcrypto" unless extension_enabled?("pgcrypto")
    change_good_job_datetime_columns(:timestamptz) { |column| "#{column} AT TIME ZONE 'UTC'" }
  end

  def down
    change_good_job_datetime_columns(:timestamp) { |column| "#{column} AT TIME ZONE 'UTC'" }
  end

  private

  def change_good_job_datetime_columns(type)
    GOOD_JOB_DATETIME_COLUMNS.each do |table, columns|
      columns.each do |column|
        change_column table, column, type, using: yield(column)
      end
    end
  end
end
