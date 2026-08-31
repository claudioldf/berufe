# frozen_string_literal: true

class PublicProfessionalProfileSerializer
  def initialize(profile)
    @profile = profile
  end

  def as_json(*)
    return nil unless profile.publicly_available?

    revision = profile.published_revision
    return nil unless revision

    selections = revision.professional_profile_services.sort_by do |selection|
      [selection.is_primary? ? 0 : 1, selection.service.name, selection.id]
    end
    verification = PublicVerificationSerializer.new(profile).as_json

    payload = {
      id: profile.id,
      public_slug: profile.public_slug,
      profile_type: revision.profile_type,
      claimed: profile.user_account.registered?,
      display_name: revision.display_name,
      headline: revision.headline,
      bio: revision.bio,
      years_experience: revision.years_experience,
      photo_url: public_photo_url,
      services: selections.map do |selection|
        {
          id: selection.service_id,
          name: selection.service.name,
          slug: selection.service.slug,
          icon: selection.service.icon,
          is_primary: selection.is_primary,
          note: selection.note
        }
      end,
      coverage: ProfessionalCoverageSerializer.new(revision).as_json,
      verification_labels: verification_labels(verification),
      evidence_summary: public_evidence_summary,
      customer_recommendations: public_customer_recommendations,
      portfolio: public_portfolio,
      relationships: public_relationships,
      social_links: {
        instagram: revision.instagram_url,
        youtube: revision.youtube_url
      },
      public_snapshot_updated_at: revision.updated_at.iso8601
    }
    payload[:indexable] = PublicIndexability.profile_indexable?(payload)
    payload
  end

  private

  attr_reader :profile

  def verification_labels(verification)
    labels = []
    labels << {type: "phone", label: "Telefone confirmado", verified_at: nil} if verification[:phone_confirmed]
    if verification[:identity]
      labels << {
        type: "identity",
        label: verification[:identity][:label],
        verified_at: verification[:identity][:verified_at]
      }
    end
    labels
  end

  def public_photo_url
    photo = profile.profile_photo
    return unless photo && photo.deleted_at.nil?

    PublicProfilePhotoImageUrl.call(photo)
  end

  def public_portfolio
    return [] if profile.external_presentation?

    profile.portfolio_items
      .select { |item| item.deleted_at.nil? }
      .sort_by { |item| [-item.submitted_at.to_f, item.id] }
      .map do |item|
        {
          id: item.id,
          title: item.title,
          description: item.description,
          service: {
            id: item.service_id,
            name: item.service.name,
            slug: item.service.slug
          },
          image_url: PublicPortfolioImageUrl.call(item)
        }
      end
  end

  def public_relationships
    PublicProfessionalRelationshipQuery
      .for_professional(profile.id)
      .includes(
        initiator_professional: %i[profile_photo published_revision],
        recipient_professional: %i[profile_photo published_revision]
      )
      .order(responded_at: :desc, id: :desc)
      .map { |relationship| serialize_relationship(relationship) }
  end

  def public_evidence_summary
    {
      registered_services: registered_service_jobs.count,
      recommendations: public_recommendation_records.count,
      hidden_recommendations: hidden_recommendation_records.count,
      worked_together_professionals: accepted_worked_together_professional_ids.count
    }
  end

  def public_customer_recommendations
    public_recommendation_records.limit(20).map do |recommendation|
      {
        id: recommendation.id,
        display_name: recommendation.display_name,
        recommendation_text: recommendation.recommendation_text,
        submitted_at: recommendation.submitted_at.iso8601,
        verification_label: RecommendationVerificationLabel.call(recommendation)
      }
    end
  end

  # Professional-declared completion, not customer-verified — the completion
  # step no longer requires the customer to confirm. See Increment 9 Decision 4.
  def registered_service_jobs
    ServiceJob.joins(:quote).where(status: "completed", quotes: {professional_id: profile.id})
  end

  def public_recommendation_records
    recommendation_scope.publicly_visible.order(submitted_at: :desc, id: :desc)
  end

  def hidden_recommendation_records
    recommendation_scope.publication_authorized.hidden_by_professional
  end

  def recommendation_scope
    CustomerRecommendation
      .joins(service_job: :quote)
      .where(quotes: {professional_id: profile.id})
  end

  def accepted_worked_together_professional_ids
    ProfessionalRelationship
      .active
      .where(status: "accepted", relationship_type: "worked_together")
      .where(
        "initiator_professional_id = :id OR recipient_professional_id = :id",
        id: profile.id
      )
      .pluck(:initiator_professional_id, :recipient_professional_id)
      .map { |initiator_id, recipient_id| (initiator_id == profile.id) ? recipient_id : initiator_id }
      .uniq
  end

  def serialize_relationship(relationship)
    other = if relationship.initiator_professional_id == profile.id
      relationship.recipient_professional
    else
      relationship.initiator_professional
    end
    other_revision = other.published_revision
    other_photo = other.profile_photo

    {
      id: relationship.id,
      type: relationship.relationship_type,
      direction: (relationship.initiator_professional_id == profile.id) ? "outgoing" : "incoming",
      note: relationship.context_note,
      professional: {
        id: other.id,
        public_slug: other.public_slug,
        display_name: other_revision.display_name,
        photo_url: public_relationship_photo_url(other_photo)
      }
    }
  end

  def public_relationship_photo_url(photo)
    return unless photo && photo.deleted_at.nil?

    PublicProfilePhotoImageUrl.call(photo)
  end
end
