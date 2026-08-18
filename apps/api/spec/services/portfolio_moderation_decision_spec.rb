# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Portfolio moderation" do
  let(:admin) do
    UserAccount.create!(
      email: "portfolio-moderation@example.com",
      password: "a-secure-admin-password",
      password_confirmation: "a-secure-admin-password",
      role: "admin",
      status: "active"
    )
  end
  let(:account) { UserAccount.create!(phone_e164: "+5547999998207", role: "professional", status: "active") }
  let(:profile) { ProfessionalProfile.create!(user_account: account, display_name: "Ana Souza") }
  let(:service) { create_selected_service }
  let(:publisher) do
    instance_double(ModerationMediaPublisher, delete: nil).tap do |fake|
      allow(fake).to receive(:publish) do |target:, target_type:|
        "moderation/#{target_type}/#{target.id}/approved.png"
      end
    end
  end
  let(:public_key) { "moderation/portfolio_item/#{item.id}/approved.png" }
  let(:context) { AdminActionContext.new(admin_user_id: admin.id, request_id: "portfolio-moderation") }
  let(:item) { create_item }

  it "publishes the approved image while preserving service and deterministic order" do
    older = create_item(title: "Trabalho anterior", submitted_at: 1.day.ago)

    decide(item, "approved")
    decide(older, "approved")

    expect(item.reload).to have_attributes(
      status: "approved",
      public_key: public_key,
      service: service,
      rejection_reason: nil
    )
    expect(PortfolioItem.publicly_visible.newest_first.pluck(:id)).to eq([item.id, older.id])
    projection = ProfessionalWorkspaceSerializer.new(profile.reload).as_json
    approved_item = projection.dig(:profile, :portfolio_items).find { |entry| entry[:id] == item.id }
    expect(approved_item).to include(
      status: "approved",
      image_url: "#{ENV.fetch("API_PUBLIC_URL")}/api/v1/public/portfolio-items/#{item.id}/image"
    )
    expect(approved_item.fetch(:image_url)).not_to include(public_key)
  end

  it "keeps rejection guidance private and excludes rejected work from public queries" do
    decide(item, "rejected", reason: "A imagem está desfocada e precisa ser substituída.")

    expect(item.reload).to have_attributes(
      status: "rejected",
      public_key: nil,
      rejection_reason: "A imagem está desfocada e precisa ser substituída."
    )
    expect(PortfolioItem.publicly_visible).not_to include(item)
    owner_item = ProfessionalWorkspaceSerializer.new(profile.reload).as_json.dig(:profile, :portfolio_items).sole
    expect(owner_item).to include(
      status: "rejected",
      rejection_reason: "A imagem está desfocada e precisa ser substituída.",
      image_url: nil
    )
  end

  it "hides public work immediately and restores it through a new public object" do
    decide(item, "approved")
    approved_key = item.reload.public_key
    allow(publisher).to receive(:publish).and_return("moderation/portfolio_item/#{item.id}/restored.png")

    decide(item, "hidden", reason: "Conteúdo ocultado após uma revisão operacional.")

    expect(item.reload).to have_attributes(status: "hidden", public_key: nil)
    expect(PortfolioItem.publicly_visible).not_to include(item)
    expect(publisher).to have_received(:delete).with(approved_key)

    decide(item, "restored")
    expect(item.reload).to have_attributes(
      status: "approved",
      public_key: "moderation/portfolio_item/#{item.id}/restored.png"
    )
    expect(ModerationAction.order(:created_at).pluck(:action)).to eq(%w[approved hidden restored])
  end

  it "removes an orphaned public object when the atomic audit append fails" do
    allow(ModerationAction).to receive(:create!).and_raise(ActiveRecord::RecordInvalid.new(ModerationAction.new))

    expect { decide(item, "approved") }.to raise_error(ModerationDecision::Invalid)

    expect(item.reload).to have_attributes(status: "pending_review", public_key: nil)
    expect(publisher).to have_received(:delete).with(public_key)
  end

  private

  def decide(target, action, reason: nil)
    ModerationDecision.new(context:, publisher:).call(
      target_type: "portfolio_item",
      target_id: target.id,
      action:,
      reason:
    )
  end

  def create_selected_service
    category = ServiceCategory.create!(
      name: "Portfólio Moderação",
      slug: "portfolio-moderacao",
      icon: "i-lucide-wrench",
      is_active: true,
      sort_order: 0
    )
    created = Service.create!(
      category:,
      name: "Eletricista",
      slug: "eletricista-portfolio-moderacao",
      icon: "i-lucide-zap",
      description: "Instalações elétricas.",
      aliases: [],
      is_active: true,
      sort_order: 0
    )
    ProfessionalProfileService.create!(
      professional_profile_revision: profile.working_revision,
      service: created,
      is_primary: true
    )
    created
  end

  def create_item(title: "Cozinha iluminada", submitted_at: Time.current)
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
      uploaded_at: 1.minute.ago,
      processed_at: Time.current,
      attached_at: Time.current
    )
    profile.portfolio_items.create!(
      media_upload: upload,
      service:,
      title:,
      status: "pending_review",
      private_key: upload.sanitized_key,
      content_type: "image/png",
      byte_size: 100,
      width: 640,
      height: 380,
      submitted_at:
    )
  end
end
