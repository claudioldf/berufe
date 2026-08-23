# frozen_string_literal: true

class ProfessionalWorkspaceSerializer
  def initialize(profile)
    @profile = profile
  end

  def as_json(*)
    {
      dashboard: serialized_dashboard,
      pending_relationships: serialized_pending_relationships,
      relationships: serialized_relationships,
      profile: {
        id: profile.id,
        public_slug: profile.public_slug,
        profile_status: profile.profile_status,
        presentation_type: profile.published_revision&.profile_type || "self_service",
        is_public: profile.publicly_available?,
        is_search_eligible: profile.search_eligible?,
        publication_blockers: profile.publication_blockers,
        revision_status: profile.working_revision.status,
        revision_rejection_reason: profile.working_revision.rejection_reason,
        has_published_revision: profile.has_self_service_publication?,
        photo: serialized_photo,
        portfolio_items: serialized_portfolio_items,
        verification: serialized_verification,
        identity: {
          display_name: profile.display_name,
          birthdate: profile.birthdate&.iso8601,
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

  def serialized_dashboard
    {
      local_date: Time.current.in_time_zone(ProfessionalDailyActivity::PRODUCT_TIME_ZONE).to_date.iso8601,
      readiness: ProfessionalDashboardReadiness.new(profile).as_json,
      change_requested_quotes: serialized_change_requested_quotes,
      recent_quotes: profile.quotes.newest_first.limit(5).map do |quote|
        ProfessionalQuoteSummarySerializer.new(quote).as_json
      end,
      recent_service_jobs: ServiceJob
        .joins(:quote)
        .where(quotes: {professional_id: profile.id})
        .includes(:customer_recommendation_request, :quote)
        .order(updated_at: :desc, id: :desc)
        .limit(5)
        .map do |service_job|
          ProfessionalServiceJobSerializer.new(service_job).as_json
        end
    }
  end

  def serialized_change_requested_quotes
    profile.quotes
      .where(status: "change_requested")
      .includes(:quote_change_requests)
      .order(customer_decided_at: :desc, id: :desc)
      .filter_map do |quote|
        latest_request = quote.quote_change_requests.first
        next unless latest_request

        {
          id: quote.id,
          quote_number: quote.quote_number,
          customer_name: quote.customer_name,
          service_description: quote.service_description,
          latest_change_request: {
            id: latest_request.id,
            revision: latest_request.requested_revision,
            message: latest_request.message,
            requested_at: latest_request.requested_at.iso8601
          }
        }
      end
  end

  def serialized_pending_relationships
    profile.received_relationships
      .active
      .where(status: "pending")
      .includes(
        initiator_professional: %i[user_account working_revision published_revision published_photo],
        recipient_professional: %i[user_account working_revision published_revision published_photo]
      )
      .order(created_at: :asc, id: :asc)
      .map { |relationship| ProfessionalRelationshipSerializer.new(relationship).as_json }
  end

  def serialized_relationships
    ProfessionalRelationship.active
      .where(status: %w[pending accepted])
      .where(
        "initiator_professional_id = :id OR recipient_professional_id = :id",
        id: profile.id
      )
      .includes(
        initiator_professional: %i[user_account working_revision published_revision published_photo],
        recipient_professional: %i[user_account working_revision published_revision published_photo]
      )
      .order(created_at: :desc, id: :desc)
      .map { |relationship| ProfessionalRelationshipSerializer.new(relationship).as_json }
  end

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
      published_image_url: profile.published_photo && PublicProfilePhotoImageUrl.call(profile.published_photo),
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
        image_url: if profile.publicly_available? && item.status.in?(%w[pending_review approved])
                     PublicPortfolioImageUrl.call(item)
                   end
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
