# frozen_string_literal: true

require "rails_helper"

RSpec.describe PublicDiscoveryDemoSeed do
  let(:data_path) { described_class.default_data_path }
  let(:image_root) { described_class.default_image_root }

  it "idempotently creates the complete API-backed demo through real media and moderation paths" do
    CatalogSeed.new.call
    AdminSeed.new.call
    seed = described_class.new(
      data_path:,
      image_root:,
      environment_name: "test"
    )

    seed.call
    counts = demo_counts
    seed.call

    expect(demo_counts).to eq(counts)
    expect(counts).to include(
      profiles: 10,
      photos: 10,
      portfolio: 22,
      verifications: 10,
      relationships: 7
    )
    marcos = ProfessionalProfile.find_by!(public_slug: "marcos-alves")
    expect(marcos).to have_attributes(profile_status: "published")
    expect(marcos.published_revision).to have_attributes(
      status: "approved",
      display_name: "Marcos Alves",
      whatsapp_e164: "+5547999991111"
    )
    expect(marcos.published_photo).to have_attributes(status: "approved")
    expect(marcos.published_photo.public_key).to be_present
    expect(marcos.portfolio_items.pluck(:status).uniq).to eq(["approved"])
    expect(marcos.verification_requests.identity.where(status: "approved").sole.public_label).to eq(
      "Identidade verificada"
    )
    expect(PublicProfessionalRelationshipQuery.for_professional(marcos.id).count).to eq(3)
  end

  it "refuses outside local/test before resolving source files or writing records" do
    logger = instance_double(ActiveSupport::Logger, warn: nil)
    seed = described_class.new(
      data_path: "/does-not-exist/professionals.json",
      image_root: "/does-not-exist/images",
      environment_name: "production",
      logger:
    )

    expect(seed.call).to be_nil
    expect(logger).to have_received(:warn).with(
      "Public discovery demo seed skipped outside local/test."
    )
    expect(ProfessionalProfile.count).to eq(0)
  end

  it "prefers explicitly configured seed paths" do
    allow(ENV).to receive(:[]).and_call_original
    allow(ENV).to receive(:[]).with("PROFESSIONAL_DEMO_SEED_PATH").and_return(
      "/tmp/professionals.json"
    )
    allow(ENV).to receive(:[]).with("PROFESSIONAL_DEMO_IMAGE_ROOT").and_return(
      "/tmp/demo-images"
    )

    expect(described_class.default_data_path).to eq(Pathname("/tmp/professionals.json"))
    expect(described_class.default_image_root).to eq(Pathname("/tmp/demo-images"))
  end

  private

  def demo_counts
    {
      profiles: ProfessionalProfile.where(
        public_slug: JSON.parse(data_path.read).pluck("slug")
      ).count,
      photos: ProfessionalProfilePhoto.count,
      portfolio: PortfolioItem.count,
      verifications: VerificationRequest.count,
      relationships: ProfessionalRelationship.count,
      uploads: MediaUpload.count,
      moderation_actions: ModerationAction.count
    }
  end
end
