# frozen_string_literal: true

require "rails_helper"

RSpec.describe ProfessionalDashboardReadiness do
  let(:account) do
    UserAccount.create!(phone_e164: "+5547999997651", role: "professional", status: "active")
  end
  let(:profile) { ProfessionalProfile.create!(user_account: account, display_name: "Ana Souza") }

  it "calculates four authoritative, equally weighted readiness steps" do
    expect(readiness).to eq(
      percentage: 0,
      steps: {
        identity_contact: false,
        service_coverage: false,
        reviewable_portfolio: false,
        approved_identity: false
      }
    )

    complete_identity_contact
    profile.working_revision.update!(
      headline: "Elétrica residencial.",
      bio: "Instalações e manutenção em Joinville."
    )
    expect(readiness).to include(percentage: 25)

    service = create_service
    profile.working_revision.professional_profile_services.create!(service:, is_primary: true)
    profile.working_revision.professional_profile_service_areas.create!(neighborhood_code: nil)
    expect(readiness).to include(percentage: 50)

    portfolio = create_portfolio(service:, status: "pending_review")
    expect(readiness).to include(percentage: 75)

    profile.verification_requests.create!(
      verification_type: "identity",
      status: "approved",
      submitted_at: Time.current
    )
    expect(readiness).to eq(
      percentage: 100,
      steps: {
        identity_contact: true,
        service_coverage: true,
        reviewable_portfolio: true,
        approved_identity: true
      }
    )

    portfolio.update!(status: "rejected")
    expect(readiness.dig(:steps, :reviewable_portfolio)).to be(false)
    expect(readiness.fetch(:percentage)).to eq(75)
  end

  it "does not count inactive supply or hidden, rejected, and deleted work" do
    complete_identity_contact
    profile.working_revision.update!(headline: "Pintura.", bio: "Pintura residencial em Joinville.")
    service = create_service
    service.update!(is_active: false)
    profile.working_revision.professional_profile_services.create!(service:, is_primary: true)
    neighborhood = Neighborhood.create!(
      code: "inactive-readiness",
      state_code: "SC",
      city_code: "Joinville",
      name: "Bairro Inativo",
      is_active: false,
      sort_order: 0
    )
    profile.working_revision.professional_profile_service_areas.create!(neighborhood_code: neighborhood.code)

    %w[rejected hidden].each do |status|
      create_portfolio(service:, status:)
    end
    deleted = create_portfolio(service:, status: "approved")
    deleted.update!(deleted_at: Time.current)

    expect(readiness).to include(percentage: 25)
    expect(readiness.fetch(:steps)).to include(
      service_coverage: false,
      reviewable_portfolio: false
    )
  end

  private

  def readiness
    described_class.new(profile.reload).as_json
  end

  def complete_identity_contact
    photo = create_public_profile_photo(profile)
    profile.update!(birthdate: Date.new(1990, 4, 12), working_photo: photo)
  end

  def create_service
    category = ServiceCategory.create!(
      name: "Readiness",
      slug: "readiness-#{SecureRandom.hex(3)}",
      icon: "i-lucide-wrench",
      is_active: true,
      sort_order: 0
    )
    Service.create!(
      category:,
      name: "Eletricista Readiness",
      slug: "eletricista-readiness-#{SecureRandom.hex(3)}",
      icon: "i-lucide-zap",
      description: "Instalações elétricas.",
      aliases: [],
      is_active: true,
      sort_order: 0
    )
  end

  def create_portfolio(service:, status:)
    upload = MediaUpload.create!(
      professional_profile: profile,
      purpose: "portfolio_image",
      state: "attached",
      declared_content_type: "image/png",
      declared_byte_size: 120,
      actual_content_type: "image/png",
      sanitized_content_type: "image/png",
      actual_byte_size: 120,
      sanitized_byte_size: 100,
      width: 640,
      height: 380,
      quarantine_key: "quarantine/#{profile.id}/#{SecureRandom.uuid}",
      sanitized_key: "sanitized/#{profile.id}/#{SecureRandom.uuid}.png",
      authorization_expires_at: 5.minutes.from_now,
      uploaded_at: 2.minutes.ago,
      processed_at: 1.minute.ago,
      attached_at: Time.current
    )
    profile.portfolio_items.create!(
      media_upload: upload,
      service:,
      title: "Trabalho residencial",
      status:,
      private_key: upload.sanitized_key,
      public_key: status.in?(%w[approved hidden]) ? "public/#{SecureRandom.uuid}.png" : nil,
      content_type: "image/png",
      byte_size: 100,
      width: 640,
      height: 380,
      submitted_at: Time.current
    )
  end
end
