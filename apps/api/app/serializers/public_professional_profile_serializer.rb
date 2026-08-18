# frozen_string_literal: true

class PublicProfessionalProfileSerializer
  def initialize(profile)
    @profile = profile
  end

  def as_json(*)
    return nil unless profile.profile_status == "published" && profile.user_account.active?

    revision = profile.published_revision
    return nil unless revision&.status == "approved"

    selections = revision.professional_profile_services.sort_by do |selection|
      [selection.is_primary? ? 0 : 1, selection.service.name, selection.id]
    end
    areas = revision.professional_profile_service_areas
    verification = PublicVerificationSerializer.new(profile).as_json

    {
      id: profile.id,
      publicSlug: profile.public_slug,
      displayName: revision.display_name,
      headline: revision.headline,
      bio: revision.bio,
      yearsExperience: revision.years_experience,
      photoUrl: public_photo_url,
      services: selections.map do |selection|
        {
          id: selection.service_id,
          name: selection.service.name,
          slug: selection.service.slug,
          isPrimary: selection.is_primary,
          note: selection.note
        }
      end,
      coverage: {
        allJoinville: areas.any? { |area| area.neighborhood_code.nil? },
        neighborhoods: areas.filter_map do |area|
          next unless area.neighborhood

          {code: area.neighborhood.code, name: area.neighborhood.name}
        end.sort_by { |area| [area[:name], area[:code]] }
      },
      verificationLabels: verification_labels(verification),
      portfolio: public_portfolio,
      relationships: public_relationships,
      socialLinks: {
        instagram: revision.instagram_url,
        youtube: revision.youtube_url
      },
      publicSnapshotUpdatedAt: revision.reviewed_at&.iso8601
    }
  end

  private

  attr_reader :profile

  def verification_labels(verification)
    labels = [{type: "phone", label: "Telefone confirmado", verifiedAt: nil}]
    if verification[:identity]
      labels << {
        type: "identity",
        label: verification[:identity][:label],
        verifiedAt: verification[:identity][:verified_at]
      }
    end
    labels
  end

  def public_photo_url
    photo = profile.published_photo
    return unless photo&.approved? && photo.public_key.present?

    PublicProfilePhotoImageUrl.call(photo)
  end

  def public_portfolio
    profile.portfolio_items
      .select { |item| item.approved? && item.deleted_at.nil? && item.public_key.present? }
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
          imageUrl: PublicPortfolioImageUrl.call(item)
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
        publicSlug: other.public_slug,
        displayName: other_revision.display_name,
        photoUrl: public_relationship_photo_url(other_photo)
      }
    }
  end

  def public_relationship_photo_url(photo)
    return unless photo&.approved? && photo.public_key.present?

    PublicProfilePhotoImageUrl.call(photo)
  end
end
