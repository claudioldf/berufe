# frozen_string_literal: true

require "rails_helper"

RSpec.describe ProfessionalProfileSubmitter do
  let(:account) do
    UserAccount.create!(phone_e164: "+5547999998150", role: "professional", status: "active")
  end
  let(:profile) do
    ProfessionalProfile.create!(user_account: account, display_name: "Ana Souza")
  end

  it "publishes the complete persisted profile immediately and is idempotent" do
    complete_required_profile
    expect(profile.reload.publication_blockers).to be_empty

    result = described_class.new.call(profile:)
    expect(result).to have_attributes(
      profile_status: "published",
      published_revision: result.working_revision,
      profile_photo: result.profile_photo
    )
    expect(result).to be_publicly_available
    expect { described_class.new.call(profile:) }.not_to change { result.reload.updated_at }
  end

  it "returns every actionable publication blocker without changing state" do
    expect do
      described_class.new.call(profile:)
    end.to raise_error(described_class::Invalid) { |error|
      expect(error.field_errors.keys).to contain_exactly(:identity, :photo, :services, :coverage)
    }

    expect(profile.reload).to have_attributes(profile_status: "draft", published_at: nil)
    expect(profile.working_revision).to be_present
  end

  it "enqueues AI copy generation on first publish when headline or bio is blank" do
    complete_required_profile

    expect { described_class.new.call(profile:) }
      .to have_enqueued_job(ProfessionalHeadlineBioGenerationJob).with(profile.working_revision.id)
  end

  it "does not enqueue AI copy generation again on idempotent re-submission" do
    complete_required_profile
    described_class.new.call(profile:)

    expect { described_class.new.call(profile:) }
      .not_to have_enqueued_job(ProfessionalHeadlineBioGenerationJob)
  end

  it "does not enqueue AI copy generation on publish when headline and bio are already authored" do
    complete_required_profile
    profile.working_revision.update!(headline: "Escrito pela profissional.", bio: "Também escrito por ela.")

    expect { described_class.new.call(profile:) }
      .not_to have_enqueued_job(ProfessionalHeadlineBioGenerationJob)
  end

  it "does not require portfolio or identity verification" do
    complete_required_profile

    expect { described_class.new.call(profile:) }.to change { profile.reload.profile_status }
      .from("draft").to("published")
    expect(profile.portfolio_items).to be_empty
    expect(profile.verification_requests).to be_empty
  end

  private

  def complete_required_profile
    ProfessionalProfileIdentityUpdater.new.call(
      profile:,
      attributes: {
        display_name: "Ana Souza",
        birthdate: "1990-04-12",
        headline: "",
        bio: "",
        years_experience: nil,
        whatsapp: "",
        instagram: "",
        youtube: ""
      }
    )
    ProfessionalProfileSupplyUpdater.new.call(
      profile:,
      services: [{service_id: selected_service.id, is_primary: true, note: nil}],
      coverage: {city_code: joinville_city.code, whole_city: true, neighborhood_codes: []}
    )
    ProfessionalProfilePhotoAttacher.new.call(profile:, media_upload_id: processed_photo.id)
  end

  def selected_service
    @selected_service ||= begin
      category = ServiceCategory.create!(
        name: "Submissão Spec",
        slug: "submissao-spec",
        icon: "i-lucide-wrench",
        is_active: true,
        sort_order: 0
      )
      Service.create!(
        category:,
        name: "Eletricista Submissão",
        slug: "eletricista-submissao",
        icon: "i-lucide-zap",
        description: "Instalações elétricas.",
        aliases: [],
        is_active: true,
        sort_order: 0
      )
    end
  end

  def processed_photo
    @processed_photo ||= MediaUpload.create!(
      professional_profile: profile,
      purpose: "profile_photo",
      state: "processed",
      declared_content_type: "image/jpeg",
      declared_byte_size: 120,
      actual_content_type: "image/jpeg",
      sanitized_content_type: "image/jpeg",
      actual_byte_size: 120,
      sanitized_byte_size: 100,
      width: 640,
      height: 960,
      quarantine_key: "quarantine/#{profile.id}/#{SecureRandom.uuid}",
      sanitized_key: "sanitized/#{profile.id}/#{SecureRandom.uuid}.jpg",
      authorization_expires_at: 5.minutes.from_now,
      uploaded_at: 1.minute.ago,
      processed_at: Time.current
    )
  end
end
