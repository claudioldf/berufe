# frozen_string_literal: true

class MediaUploadProcessingJob < ApplicationJob
  queue_as :default

  def perform(media_upload_id)
    upload = MediaUpload.find_by(id: media_upload_id)
    return unless upload

    MediaUploadProcessor.new.call(upload:)
  end
end
