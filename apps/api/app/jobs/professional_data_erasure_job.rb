# frozen_string_literal: true

class ProfessionalDataErasureJob < ApplicationJob
  queue_as :default

  retry_on StandardError, wait: :polynomially_longer, attempts: 10

  def perform(request_id, now: Time.current, storage: MediaStorage.build)
    request_record = DataErasureRequest.find_by(id: request_id)
    return unless request_record

    request_record.with_lock do
      return if request_record.status == "completed"

      request_record.update!(status: "processing", failure_code: nil)
      account = UserAccount.includes(:professional_profile).find_by(id: request_record.target_user_account_id)
      unless account&.professional_profile
        request_record.update!(status: "completed", completed_at: now, target_user_account_id: nil)
        return
      end

      profile = account.professional_profile
      delete_storage_objects!(profile, storage:)
      erase_database_records!(request_record:, account:, profile:, now:)
    end
  rescue => error
    request_record&.update_columns(status: "failed", failure_code: "processing_error", updated_at: now)
    Rails.error.report(error, context: {data_erasure_request_id: request_id})
    raise
  end

  private

  def delete_storage_objects!(profile, storage:)
    storage_objects(profile).each do |scope, key|
      storage.delete(scope:, key:)
    end
  end

  def storage_objects(profile)
    objects = []
    profile.media_uploads.pluck(:quarantine_key, :sanitized_key).each do |quarantine_key, sanitized_key|
      objects << [:private, quarantine_key]
      objects << [:private, sanitized_key] if sanitized_key.present?
    end
    profile.profile_photos.pluck(:private_key, :public_key).each do |private_key, public_key|
      objects << [:private, private_key]
      objects << [:public, public_key] if public_key.present?
    end
    profile.portfolio_items.pluck(:private_key, :public_key).each do |private_key, public_key|
      objects << [:private, private_key]
      objects << [:public, public_key] if public_key.present?
    end
    VerificationFile.joins(:verification_request)
      .where(verification_requests: {professional_profile_id: profile.id})
      .where(deleted_at: nil)
      .pluck(:private_key)
      .each { |key| objects << [:private, key] }
    objects.uniq
  end

  def erase_database_records!(request_record:, account:, profile:, now:)
    ids = target_ids(profile)

    ApplicationRecord.transaction do
      retain_minimal_legal_records!(request_record:, account:, profile:, ids:, now:)

      CustomerRecommendationRequest.where(service_job_id: ids.fetch(:service_job_ids)).delete_all
      CustomerRecommendation.where(service_job_id: ids.fetch(:service_job_ids)).delete_all
      ServiceJob.where(id: ids.fetch(:service_job_ids)).delete_all
      QuoteChangeRequest.where(quote_id: ids.fetch(:quote_ids)).delete_all
      QuoteItem.where(quote_id: ids.fetch(:quote_ids)).delete_all
      Quote.where(id: ids.fetch(:quote_ids)).delete_all
      Customer.where(professional_id: profile.id).delete_all
      ProfessionalRelationship.where(
        "initiator_professional_id = :id OR recipient_professional_id = :id",
        id: profile.id
      ).delete_all
      ProfessionalDailyMetric.where(professional_id: profile.id).delete_all
      ProfessionalDailyActivity.where(professional_id: profile.id).delete_all

      VerificationFileAccessEvent.where(verification_file_id: ids.fetch(:verification_file_ids)).delete_all
      VerificationFile.where(id: ids.fetch(:verification_file_ids)).delete_all
      VerificationRequest.where(id: ids.fetch(:verification_request_ids)).delete_all
      delete_moderation_records!(ids)

      profile.update_columns(
        working_revision_id: nil,
        published_revision_id: nil,
        approved_revision_id: nil,
        working_photo_id: nil,
        published_photo_id: nil,
        approved_photo_id: nil,
        updated_at: now
      )
      PortfolioItem.where(id: ids.fetch(:portfolio_item_ids)).delete_all
      ProfessionalProfilePhoto.where(id: ids.fetch(:photo_ids)).delete_all
      ProfessionalProfileServiceArea.where(professional_profile_revision_id: ids.fetch(:revision_ids)).delete_all
      ProfessionalProfileService.where(professional_profile_revision_id: ids.fetch(:revision_ids)).delete_all
      ProfessionalProfileRevision.where(id: ids.fetch(:revision_ids)).delete_all
      MediaUpload.where(professional_profile_id: profile.id).delete_all

      profile.delete
      ApplicationSession.where(user_account_id: account.id).delete_all
      account.delete
      request_record.update!(
        status: "completed",
        completed_at: now,
        failure_code: nil,
        target_user_account_id: nil
      )
    end
  end

  def target_ids(profile)
    quote_ids = Quote.where(professional_id: profile.id).pluck(:id)
    verification_request_ids = VerificationRequest.where(professional_profile_id: profile.id).pluck(:id)
    {
      quote_ids:,
      service_job_ids: ServiceJob.where(quote_id: quote_ids).pluck(:id),
      revision_ids: ProfessionalProfileRevision.where(professional_profile_id: profile.id).pluck(:id),
      photo_ids: ProfessionalProfilePhoto.where(professional_profile_id: profile.id).pluck(:id),
      portfolio_item_ids: PortfolioItem.where(professional_profile_id: profile.id).pluck(:id),
      verification_request_ids:,
      verification_file_ids: VerificationFile.where(verification_request_id: verification_request_ids).pluck(:id)
    }
  end

  def retain_minimal_legal_records!(request_record:, account:, profile:, ids:, now:)
    common = {subject_digest: request_record.subject_digest, retained_until: request_record.retained_until}

    if account.terms_accepted_at
      LegalRetentionRecord.create!(
        **common,
        record_type: "legal_acceptance",
        occurred_at: account.terms_accepted_at,
        metadata: {
          terms_version: account.terms_version,
          privacy_notice_version: account.privacy_notice_version
        }
      )
    end

    CustomerRecommendation.where(service_job_id: ids.fetch(:service_job_ids)).find_each do |recommendation|
      LegalRetentionRecord.create!(
        **common,
        record_type: "recommendation_consent",
        occurred_at: recommendation.publication_authorized_at,
        metadata: {
          privacy_notice_version: recommendation.privacy_notice_version,
          withdrawn: recommendation.publication_withdrawn_at.present?
        }
      )
    end

    Quote.where(id: ids.fetch(:quote_ids)).where.not(terms_accepted_at: nil).find_each do |quote|
      LegalRetentionRecord.create!(
        **common,
        record_type: "quote_acceptance",
        occurred_at: quote.terms_accepted_at,
        metadata: {quote_status: quote.status}
      )
    end

    ProfessionalRelationship.where(initiator_professional_id: profile.id)
      .where.not(contact_publication_attested_at: nil)
      .find_each do |relationship|
        LegalRetentionRecord.create!(
          **common,
          record_type: "referral_attestation",
          occurred_at: relationship.contact_publication_attested_at,
          metadata: {source: relationship.source}
        )
      end

    target_groups(ids).each do |target_type, target_ids|
      ModerationAction.where(target_type:, target_id: target_ids).find_each do |action|
        LegalRetentionRecord.create!(
          **common,
          record_type: "moderation_event",
          occurred_at: action.created_at,
          metadata: {target_type:, action: action.action}
        )
      end
    end
  end

  def delete_moderation_records!(ids)
    target_groups(ids).each do |target_type, target_ids|
      ModerationAction.where(target_type:, target_id: target_ids).delete_all
      next unless target_type.in?(%w[profile_photo portfolio_item])

      ModerationMediaAccessEvent.where(target_type:, target_id: target_ids).delete_all
    end
  end

  def target_groups(ids)
    {
      "profile_revision" => ids.fetch(:revision_ids),
      "profile_photo" => ids.fetch(:photo_ids),
      "portfolio_item" => ids.fetch(:portfolio_item_ids),
      "verification_request" => ids.fetch(:verification_request_ids)
    }
  end
end
