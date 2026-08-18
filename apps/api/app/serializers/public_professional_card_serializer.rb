# frozen_string_literal: true

class PublicProfessionalCardSerializer
  def initialize(profile, matching_service: nil)
    @profile = profile
    @matching_service = matching_service
  end

  def as_json(*)
    revision = profile.published_revision
    primary_service = revision.professional_profile_services.find(&:is_primary)
    areas = revision.professional_profile_service_areas
    verification = PublicVerificationSerializer.new(profile).as_json

    {
      id: profile.id,
      publicSlug: profile.public_slug,
      displayName: revision.display_name,
      headline: revision.headline,
      photoUrl: public_photo_url,
      primaryService: primary_service && {
        id: primary_service.service_id,
        name: primary_service.service.name,
        slug: primary_service.service.slug
      },
      matchingService: serialize_service(matching_service || primary_service&.service),
      coverage: {
        allJoinville: areas.any? { |area| area.neighborhood_code.nil? },
        neighborhoods: areas.filter_map do |area|
          next unless area.neighborhood

          {code: area.neighborhood.code, name: area.neighborhood.name}
        end
      },
      verificationLabels: verification_labels(verification),
      portfolioCount: profile.portfolio_items.count { |item| item.status == "approved" && item.deleted_at.nil? },
      relationshipCount: PublicProfessionalRelationshipQuery.for_professional(profile.id).count,
      publicSnapshotUpdatedAt: revision.reviewed_at&.iso8601
    }
  end

  private

  attr_reader :profile, :matching_service

  def serialize_service(service)
    return unless service

    {id: service.id, name: service.name, slug: service.slug}
  end

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
end
