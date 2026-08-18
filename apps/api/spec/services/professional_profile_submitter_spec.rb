# frozen_string_literal: true

require "rails_helper"

RSpec.describe ProfessionalProfileSubmitter do
  let(:account) do
    UserAccount.create!(phone_e164: "+5547999998150", role: "professional", status: "active")
  end
  let(:profile) do
    ProfessionalProfile.create!(user_account: account, display_name: "Ana Souza")
  end

  it "atomically submits a complete persisted profile and is idempotent" do
    complete_checklist

    result = described_class.new.call(profile:)
    submitted_at = result.working_revision.submitted_at

    expect(result).to have_attributes(profile_status: "pending_review")
    expect(result.working_revision).to have_attributes(status: "pending_review")
    expect(submitted_at).to be_present

    expect(described_class.new.call(profile:).working_revision.submitted_at).to eq(submitted_at)
  end

  it "returns every actionable missing checklist area without changing state" do
    expect do
      described_class.new.call(profile:)
    end.to raise_error(described_class::Invalid) { |error|
      expect(error.field_errors.keys).to contain_exactly(
        :identity,
        :services,
        :coverage,
        :portfolio,
        :verification
      )
    }

    expect(profile.reload).to have_attributes(profile_status: "draft")
    expect(profile.working_revision).to have_attributes(status: "draft", submitted_at: nil)
  end

  it "does not count rejected or deleted evidence as reviewable" do
    complete_identity_and_supply
    create_portfolio(status: "rejected", deleted_at: nil)
    create_portfolio(status: "approved", deleted_at: Time.current)
    create_verification(status: "rejected")

    expect do
      described_class.new.call(profile:)
    end.to raise_error(described_class::Invalid) { |error|
      expect(error.field_errors.keys).to contain_exactly(:portfolio, :verification)
    }
  end

  private

  def complete_checklist
    complete_identity_and_supply
    create_portfolio(status: "pending_review", deleted_at: nil)
    create_verification(status: "pending_review")
  end

  def complete_identity_and_supply
    ProfessionalProfileIdentityUpdater.new.call(
      profile:,
      attributes: {
        display_name: "Ana Souza",
        headline: "Elétrica residencial.",
        bio: "Instalações e manutenção em Joinville.",
        years_experience: 8,
        whatsapp: account.phone_e164,
        instagram: "",
        youtube: ""
      }
    )
    service = selected_service
    ProfessionalProfileSupplyUpdater.new.call(
      profile:,
      services: [{service_id: service.id, is_primary: true, note: nil}],
      coverage: {all_joinville: true, neighborhood_codes: []}
    )
  end

  def selected_service
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

  def create_portfolio(status:, deleted_at:)
    upload = processed_upload("portfolio_image")
    profile.portfolio_items.create!(
      media_upload: upload,
      service: profile.working_revision.services.first,
      title: "Cozinha iluminada",
      status:,
      private_key: upload.sanitized_key,
      content_type: "image/png",
      byte_size: 100,
      width: 640,
      height: 380,
      submitted_at: Time.current,
      deleted_at:
    )
  end

  def create_verification(status:)
    upload = processed_upload("verification_identity")
    request_record = profile.verification_requests.create!(
      verification_type: "identity",
      status:,
      submitted_at: Time.current
    )
    request_record.create_verification_file!(
      media_upload: upload,
      private_key: upload.sanitized_key,
      content_type: "image/png",
      byte_size: 100,
      width: 640,
      height: 960,
      uploaded_at: Time.current
    )
  end

  def processed_upload(purpose)
    MediaUpload.create!(
      professional_profile: profile,
      purpose:,
      state: "attached",
      declared_content_type: "image/png",
      declared_byte_size: 120,
      actual_content_type: "image/png",
      sanitized_content_type: "image/png",
      actual_byte_size: 120,
      sanitized_byte_size: 100,
      width: 640,
      height: (purpose == "portfolio_image") ? 380 : 960,
      quarantine_key: "quarantine/#{profile.id}/#{SecureRandom.uuid}",
      sanitized_key: "sanitized/#{profile.id}/#{SecureRandom.uuid}.png",
      authorization_expires_at: 5.minutes.from_now,
      uploaded_at: 1.minute.ago,
      processed_at: Time.current,
      attached_at: Time.current
    )
  end
end
