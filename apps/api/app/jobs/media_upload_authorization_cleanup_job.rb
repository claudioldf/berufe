# frozen_string_literal: true

class MediaUploadAuthorizationCleanupJob < ApplicationJob
  queue_as :default

  def perform(now: Time.current, storage: MediaStorage.build)
    MediaUpload.where(state: "authorized", authorization_expires_at: ..now).find_each do |upload|
      upload.with_lock do
        next unless upload.authorized? && upload.authorization_expired?(now)

        storage.delete(scope: :private, key: upload.quarantine_key)
        upload.update!(state: "expired", failure_code: "authorization_expired")
      end
    rescue => error
      Rails.error.report(error, context: {media_upload_id: upload.id})
    end
  end
end
