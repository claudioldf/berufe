# frozen_string_literal: true

class VerificationFileRetentionCleanupJob < ApplicationJob
  queue_as :default

  RETENTION_PERIOD = 30.days

  def perform(now: Time.current, storage: MediaStorage.build)
    VerificationFile
      .joins(:verification_request)
      .where(deleted_at: nil)
      .where(verification_requests: {status: %w[approved rejected expired]})
      .where(<<~SQL.squish, cutoff: now - RETENTION_PERIOD)
        COALESCE(verification_requests.expired_at, verification_requests.reviewed_at) <= :cutoff
      SQL
      .find_each do |file|
        delete_eligible(file, now:, storage:)
      rescue => error
        Rails.error.report(error, context: {verification_file_id: file.id})
      end
  end

  private

  def delete_eligible(file, now:, storage:)
    file.with_lock do
      file.reload
      request_record = file.verification_request.reload
      return if file.deleted_at
      return unless request_record.status.in?(%w[approved rejected expired])
      decision_at = request_record.expired_at || request_record.reviewed_at
      return unless decision_at && decision_at <= now - RETENTION_PERIOD

      storage.delete(scope: :private, key: file.private_key)
      file.update!(deleted_at: now)
    end
  end
end
