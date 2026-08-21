# frozen_string_literal: true

class PublicProfessionalProfileSerializer
  def initialize(profile)
    @profile = profile
  end

  def as_json(*)
    return nil unless profile.publicly_available?

    revision = profile.published_revision
    return nil unless revision&.status&.in?(%w[pending_review approved])

    selections = revision.professional_profile_services.sort_by do |selection|
      [selection.is_primary? ? 0 : 1, selection.service.name, selection.id]
    end
    areas = revision.professional_profile_service_areas
    verification = PublicVerificationSerializer.new(profile).as_json

    {
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
          is_primary: selection.is_primary,
          note: selection.note
        }
      end,
      coverage: {
        all_joinville: areas.any? { |area| area.neighborhood_code.nil? },
        neighborhoods: areas.filter_map do |area|
          next unless area.neighborhood

          {code: area.neighborhood.code, name: area.neighborhood.name}
        end.sort_by { |area| [area[:name], area[:code]] }
      },
      verification_labels: verification_labels(verification),
      portfolio: public_portfolio,
      relationships: public_relationships,
      social_links: {
        instagram: revision.instagram_url,
        youtube: revision.youtube_url
      },
      public_snapshot_updated_at: (revision.submitted_at || revision.created_at).iso8601
    }
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
    photo = profile.published_photo
    return unless photo&.status&.in?(%w[pending_review approved])

    PublicProfilePhotoImageUrl.call(photo)
  end

  def public_portfolio
    return [] if profile.external_presentation?

    profile.portfolio_items
      .select { |item| item.status.in?(%w[pending_review approved]) && item.deleted_at.nil? }
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
        initiator_professional: %i[published_photo published_revision],
        recipient_professional: %i[published_photo published_revision]
      )
      .order(responded_at: :desc, id: :desc)
      .map { |relationship| serialize_relationship(relationship) }
  end

  def serialize_relationship(relationship)
    other = if relationship.initiator_professional_id == profile.id
      relationship.recipient_professional
    else
      relationship.initiator_professional
    end
    other_revision = other.published_revision
    other_photo = other.published_photo

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
    return unless photo&.status&.in?(%w[pending_review approved])

    PublicProfilePhotoImageUrl.call(photo)
  end
end
