# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Application session configuration" do
  it "uses the documented five-minute activity-write throttle" do
    expect(Rails.configuration.x.berufe.session_activity_write_interval_seconds).to eq(300)
  end

  it "schedules expired authentication-record cleanup through GoodJob" do
    cleanup = Rails.configuration.good_job.cron.fetch(:authentication_records_cleanup)

    expect(cleanup).to include(
      cron: "17 * * * *",
      class: "AuthenticationRecordsCleanupJob"
    )
  end

  it "schedules abandoned upload authorization cleanup through GoodJob" do
    cleanup = Rails.configuration.good_job.cron.fetch(:media_upload_authorization_cleanup)

    expect(cleanup).to include(
      cron: "*/10 * * * *",
      class: "MediaUploadAuthorizationCleanupJob"
    )
  end

  it "schedules decided identity-evidence retention cleanup daily" do
    cleanup = Rails.configuration.good_job.cron.fetch(:verification_file_retention_cleanup)

    expect(cleanup).to include(
      cron: "43 3 * * *",
      class: "VerificationFileRetentionCleanupJob"
    )
  end

  it "schedules the remaining published retention controls" do
    cron = Rails.configuration.good_job.cron

    expect(cron.fetch(:media_retention_cleanup)).to include(class: "MediaRetentionCleanupJob")
    expect(cron.fetch(:customer_recommendation_retention_cleanup)).to include(
      class: "CustomerRecommendationRetentionCleanupJob"
    )
    expect(cron.fetch(:lgpd_audit_retention_cleanup)).to include(class: "LgpdAuditRetentionCleanupJob")
  end
end
