# frozen_string_literal: true

module ProfessionalProfileSpecHelpers
  def make_profile_publicly_eligible(profile, revision: profile.working_revision, reviewed_at: Time.current)
    profile.user_account.update_columns(
      phone_verified_at: profile.user_account.phone_verified_at || reviewed_at,
      registered_at: profile.user_account.registered_at || reviewed_at
    )
    ensure_public_supply(revision)
    revision.update!(updated_at: reviewed_at)
    photo = profile.profile_photo || create_public_profile_photo(profile, reviewed_at:)
    profile.update!(
      birthdate: profile.birthdate || Date.new(1990, 1, 1),
      profile_status: "published",
      published_at: profile.published_at || reviewed_at,
      working_revision: revision,
      published_revision: revision,
      profile_photo: photo
    )
    profile.reload
  end

  def ensure_public_supply(revision)
    unless revision.professional_profile_services.exists?
      category = ServiceCategory.find_or_create_by!(slug: "spec-public-profile") do |record|
        record.name = "Perfil Público Spec"
        record.icon = "i-lucide-wrench"
        record.is_active = true
        record.sort_order = 0
      end
      service = Service.create!(
        category:,
        name: "Serviço #{revision.professional_profile_id}",
        slug: "servico-#{revision.professional_profile_id}",
        icon: "i-lucide-wrench",
        description: "Serviço usado por um perfil público de teste.",
        aliases: [],
        is_active: true,
        sort_order: 0
      )
      revision.professional_profile_services.create!(service:, is_primary: true)
    end
    city = revision.professional_profile_service_areas.first&.neighborhood&.city || joinville_city
    revision.update!(
      coverage_city: city,
      covers_whole_city: revision.professional_profile_service_areas.none?
    )
  end

  def create_public_profile_photo(profile, reviewed_at: Time.current)
    upload = MediaUpload.create!(
      professional_profile: profile,
      purpose: "profile_photo",
      state: "attached",
      declared_content_type: "image/jpeg",
      declared_byte_size: 100,
      actual_content_type: "image/jpeg",
      sanitized_content_type: "image/jpeg",
      actual_byte_size: 100,
      sanitized_byte_size: 100,
      width: 640,
      height: 960,
      quarantine_key: "quarantine/#{profile.id}/#{SecureRandom.uuid}",
      sanitized_key: "sanitized/#{profile.id}/#{SecureRandom.uuid}.jpg",
      authorization_expires_at: 5.minutes.from_now,
      uploaded_at: 1.minute.ago,
      processed_at: reviewed_at,
      attached_at: reviewed_at
    )
    profile.profile_photos.create!(
      media_upload: upload,
      private_key: upload.sanitized_key,
      content_type: "image/jpeg",
      byte_size: 100,
      width: 640,
      height: 960,
      submitted_at: reviewed_at
    )
  end
end
