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
        is_indexable: indexable?,
        suspension_reason: profile.suspension_reason,
        publication_blockers: profile.publication_blockers,
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

  def indexable?
    return false unless profile.publicly_available?

    PublicIndexability.profile_indexable?(PublicProfessionalProfileSerializer.new(profile).as_json)
  end

  def serialized_dashboard
    {
      local_date: Time.current.in_time_zone(ProfessionalDailyActivity::PRODUCT_TIME_ZONE).to_date.iso8601,
      readiness: ProfessionalDashboardReadiness.new(profile).as_json,
      action_items: ProfessionalActionInboxQuery.new.call(profile:).map do |item|
        {
          id: item.id,
          kind: item.kind,
          title: item.title,
          subtitle: item.subtitle,
          sort_at: item.sort_at.iso8601
        }
      end,
      recent_quotes: profile.quotes.newest_first.limit(5).map do |quote|
        ProfessionalQuoteSummarySerializer.new(quote).as_json
      end,
      recent_service_jobs: ServiceJob
        .joins(:quote)
        .where(quotes: {professional_id: profile.id}, status: "approved")
        .includes(:customer_recommendation_request, :quote)
        .order(updated_at: :desc, id: :desc)
        .limit(5)
        .map do |service_job|
          ProfessionalServiceJobSerializer.new(service_job).as_json
        end
    }
  end

  def serialized_pending_relationships
    profile.received_relationships
      .active
      .where(status: "pending")
      .includes(
        initiator_professional: %i[user_account working_revision published_revision profile_photo],
        recipient_professional: %i[user_account working_revision published_revision profile_photo]
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
        initiator_professional: %i[user_account working_revision published_revision profile_photo],
        recipient_professional: %i[user_account working_revision published_revision profile_photo]
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
    current = profile.profile_photo
    latest_upload = profile.media_uploads.where(purpose: "profile_photo").order(created_at: :desc, id: :desc).first
    latest_upload = nil if latest_upload&.attached?
    {
      current: current && {
        id: current.id,
        submitted_at: current.submitted_at.iso8601
      },
      has_photo: current.present?,
      image_url: current && ProfessionalProfilePhotoImageUrl.call(current),
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
        submitted_at: item.submitted_at.iso8601,
        image_url: ProfessionalPortfolioImageUrl.call(item)
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
    ProfessionalCoverageSerializer.new(profile.working_revision).as_json
  end
end
