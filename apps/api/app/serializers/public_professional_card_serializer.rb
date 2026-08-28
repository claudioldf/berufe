# frozen_string_literal: true

class PublicProfessionalCardSerializer
  def initialize(profile, matching_service: nil)
    @profile = profile
    @matching_service = matching_service
  end

  def as_json(*)
    revision = profile.published_revision
    primary_service = revision.professional_profile_services.find(&:is_primary)
    verification = PublicVerificationSerializer.new(profile).as_json

    {
      id: profile.id,
      public_slug: profile.public_slug,
      profile_type: revision.profile_type,
      claimed: profile.user_account.registered?,
      display_name: revision.display_name,
      headline: revision.headline,
      photo_url: public_photo_url,
      primary_service: primary_service && {
        id: primary_service.service_id,
        name: primary_service.service.name,
        slug: primary_service.service.slug
      },
      matching_service: serialize_service(matching_service || primary_service&.service),
      coverage: ProfessionalCoverageSerializer.new(revision).as_json,
      verification_labels: verification_labels(verification),
      portfolio_count: profile.portfolio_items.count do |item|
        item.status.in?(%w[pending_review approved]) && item.deleted_at.nil?
      end,
      relationship_count: PublicProfessionalRelationshipQuery.for_professional(profile.id).count,
      public_snapshot_updated_at: (revision.submitted_at || revision.created_at).iso8601
    }
  end

  private

  attr_reader :profile, :matching_service

  def serialize_service(service)
    return unless service

    {id: service.id, name: service.name, slug: service.slug}
  end

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
end
