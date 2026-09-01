# frozen_string_literal: true

class MediaRetentionCleanupJob < ApplicationJob
  queue_as :default

  RETENTION_PERIOD = 30.days

  def perform(now: Time.current, storage: MediaStorage.build)
    cutoff = now - RETENTION_PERIOD
    cleanup_portfolio_items(cutoff:, storage:)
    cleanup_profile_photos(cutoff:, storage:)
    cleanup_unattached_uploads(cutoff:, storage:)
  end

  private

  def cleanup_portfolio_items(cutoff:, storage:)
    PortfolioItem
      .where(deleted_at: ..cutoff)
      .find_each do |item|
        item.with_lock do
          item.reload
          eligible_deleted_item = item.deleted_at.present? && item.deleted_at <= cutoff
          next unless eligible_deleted_item

          delete_media_key(storage:, private_key: item.private_key)
          upload_id = item.media_upload_id
          item.delete
          delete_upload_if_unattached(upload_id, storage:)
        end
      rescue => error
        Rails.error.report(error, context: {portfolio_item_id: item.id})
      end
  end

  def cleanup_profile_photos(cutoff:, storage:)
    ProfessionalProfilePhoto.where(deleted_at: ..cutoff).find_each do |photo|
      photo.with_lock do
        photo.reload
        next unless photo.deleted_at.present? && photo.deleted_at <= cutoff
        next if photo_is_referenced?(photo)

        delete_media_key(storage:, private_key: photo.private_key)
        upload_id = photo.media_upload_id
        photo.delete
        delete_upload_if_unattached(upload_id, storage:)
      end
    rescue => error
      Rails.error.report(error, context: {professional_profile_photo_id: photo.id})
    end
  end

  def cleanup_unattached_uploads(cutoff:, storage:)
    MediaUpload.where(updated_at: ..cutoff).find_each do |upload|
      delete_upload_if_unattached(upload.id, storage:)
    rescue => error
      Rails.error.report(error, context: {media_upload_id: upload.id})
    end
  end

  def delete_upload_if_unattached(upload_id, storage:)
    upload = MediaUpload.lock.find_by(id: upload_id)
    return unless upload
    return if PortfolioItem.exists?(media_upload_id: upload.id)
    return if ProfessionalProfilePhoto.exists?(media_upload_id: upload.id)
    return if VerificationFile.exists?(media_upload_id: upload.id)

    storage.delete(scope: :private, key: upload.quarantine_key)
    storage.delete(scope: :private, key: upload.sanitized_key) if upload.sanitized_key.present?
    upload.delete
  end

  def photo_is_referenced?(photo)
    ProfessionalProfile.where(profile_photo_id: photo.id).exists?
  end

  def delete_media_key(storage:, private_key:)
    storage.delete(scope: :private, key: private_key)
  end
end
