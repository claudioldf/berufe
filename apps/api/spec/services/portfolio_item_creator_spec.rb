# frozen_string_literal: true

require "rails_helper"

RSpec.describe PortfolioItemCreator do
  let(:account) do
    UserAccount.create!(phone_e164: "+5547999998143", role: "professional", status: "active")
  end
  let(:profile) do
    ProfessionalProfile.create!(user_account: account, display_name: "Ana Souza")
  end
  let(:service) { create_selected_service }

  it "attaches one processed owned image to a selected service" do
    upload = processed_upload

    item = described_class.new.call(
      profile:,
      attributes: {
        media_upload_id: upload.id,
        service_id: service.id,
        title: "  Cozinha iluminada  ",
        description: "  Instalação completa.  "
      }
    )

    expect(item).to have_attributes(
      title: "Cozinha iluminada",
      description: "Instalação completa.",
      status: "pending_review",
      service:,
      private_key: upload.sanitized_key
    )
    expect(upload.reload).to be_attached
  end

  it "requires an active service selected by the working profile revision" do
    unselected = create_service(slug: "pintura-nao-selecionada")

    expect do
      described_class.new.call(
        profile:,
        attributes: {
          media_upload_id: processed_upload.id,
          service_id: unselected.id,
          title: "Pintura",
          description: ""
        }
      )
    end.to raise_error(described_class::Invalid) { |error|
      expect(error.field_errors[:service_id]).to be_present
    }
  end

  it "enforces at most twelve non-deleted items while allowing a slot after soft deletion" do
    service
    12.times { |index| create_item(index:) }

    expect do
      described_class.new.call(
        profile:,
        attributes: valid_attributes(processed_upload)
      )
    end.to raise_error(described_class::Invalid) { |error|
      expect(error.field_errors[:base]).to include("o portfólio já possui 12 trabalhos")
    }

    PortfolioItemDeleter.new.call(item: profile.portfolio_items.first)
    expect do
      described_class.new.call(
        profile:,
        attributes: valid_attributes(processed_upload)
      )
    end.to change { profile.portfolio_items.active.count }.from(11).to(12)
  end

  it "orders only approved active items newest first with ID as tie-breaker" do
    service
    submitted_at = Time.zone.parse("2026-08-17 12:00:00")
    lower_id = "00000000-0000-4000-8000-000000000001"
    higher_id = "00000000-0000-4000-8000-000000000002"
    create_item(index: 1, id: lower_id, status: "approved", submitted_at:)
    create_item(index: 2, id: higher_id, status: "approved", submitted_at:)
    create_item(index: 3, status: "pending_review", submitted_at: 1.day.from_now)
    create_item(index: 4, status: "approved", submitted_at: 1.day.ago, deleted_at: Time.current)

    expect(PortfolioItem.publicly_visible.newest_first.pluck(:id)).to eq([higher_id, lower_id])
  end

  private

  def valid_attributes(upload)
    {
      media_upload_id: upload.id,
      service_id: service.id,
      title: "Cozinha iluminada",
      description: "Instalação completa."
    }
  end

  def create_selected_service
    created = create_service(slug: "eletricista-portfolio")
    ProfessionalProfileService.create!(
      professional_profile_revision: profile.working_revision,
      service: created,
      is_primary: true
    )
    created
  end

  def create_service(slug:)
    category = ServiceCategory.find_or_create_by!(slug: "portfolio-spec") do |record|
      record.name = "Portfólio Spec"
      record.icon = "i-lucide-wrench"
      record.is_active = true
      record.sort_order = 0
    end
    Service.create!(
      category:,
      name: slug.humanize,
      slug:,
      icon: "i-lucide-wrench",
      description: "Serviço de teste.",
      aliases: [],
      is_active: true,
      sort_order: 0
    )
  end

  def processed_upload
    MediaUpload.create!(
      professional_profile: profile,
      purpose: "portfolio_image",
      state: "processed",
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
      uploaded_at: 1.minute.ago,
      processed_at: Time.current
    )
  end

  def create_item(index:, id: nil, status: "pending_review", submitted_at: index.minutes.ago, deleted_at: nil)
    attributes = {
      media_upload: processed_upload,
      service:,
      title: "Trabalho #{index}",
      status:,
      private_key: "sanitized/#{profile.id}/item-#{index}-#{SecureRandom.uuid}.png",
      content_type: "image/png",
      byte_size: 100,
      width: 640,
      height: 380,
      submitted_at:,
      deleted_at:
    }
    attributes[:id] = id if id
    profile.portfolio_items.create!(**attributes)
  end
end
