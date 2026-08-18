# frozen_string_literal: true

class ProfessionalWorkspaceSerializer
  def initialize(profile)
    @profile = profile
  end

  def as_json(*)
    {
      profile: {
        id: profile.id,
        public_slug: profile.public_slug,
        profile_status: profile.profile_status,
        revision_status: profile.working_revision.status,
        revision_rejection_reason: profile.working_revision.rejection_reason,
        has_published_revision: profile.published_revision.present?,
        photo: serialized_photo,
        portfolio_items: serialized_portfolio_items,
        verification: serialized_verification,
        identity: {
          display_name: profile.display_name,
          headline: profile.headline.to_s,
          bio: profile.bio.to_s,
          years_experience: profile.years_experience,
          whatsapp: profile.whatsapp_e164 || profile.user_account.phone_e164,
          instagram: profile.instagram_url,
          youtube: profile.youtube_url
        },
        services: serialized_services,
        coverage: serialized_coverage
      }
    }
  end

  private

  attr_reader :profile

  def serialized_services
    profile.working_revision.professional_profile_services.includes(:service).map do |selection|
      {
        id: selection.service_id,
        name: selection.service.name,
        is_primary: selection.is_primary,
        note: selection.note
      }
    end
  end

  def serialized_photo
    current = profile.working_photo
    latest_upload = profile.media_uploads.where(purpose: "profile_photo").order(created_at: :desc, id: :desc).first
    latest_upload = nil if latest_upload&.attached? && current&.media_upload_id == latest_upload.id
    {
      current: current && {
        id: current.id,
        status: current.status,
        rejection_reason: current.rejection_reason,
        submitted_at: current.submitted_at.iso8601
      },
      has_published_photo: profile.published_photo.present?,
      latest_upload: latest_upload && MediaUploadSerializer.new(latest_upload).as_json
    }
  end

  def serialized_portfolio_items
    profile.portfolio_items.active.newest_first.includes(:service).map do |item|
      {
        id: item.id,
        title: item.title,
        description: item.description,
        service: {id: item.service_id, name: item.service.name},
        status: item.status,
        rejection_reason: item.rejection_reason,
        submitted_at: item.submitted_at.iso8601,
        image_url: item.approved? ? PublicPortfolioImageUrl.call(item) : nil
      }
    end
  end

  def serialized_verification
    request_record = profile.verification_requests.identity.newest_first.first
    {
      current: request_record && {
        id: request_record.id,
        verification_type: request_record.verification_type,
        status: request_record.status,
        rejection_reason: request_record.rejected? ? request_record.review_note : nil,
        submitted_at: request_record.submitted_at.iso8601
      }
    }
  end

  def serialized_coverage
    areas = profile.working_revision.professional_profile_service_areas.includes(:neighborhood)
    {
      all_joinville: areas.any? { |area| area.neighborhood_code.nil? },
      neighborhoods: areas.filter_map do |area|
        next unless area.neighborhood

        {code: area.neighborhood.code, name: area.neighborhood.name}
      end
    }
  end
end
