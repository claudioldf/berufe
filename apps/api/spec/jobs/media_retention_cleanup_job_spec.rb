# frozen_string_literal: true

require "rails_helper"

RSpec.describe MediaRetentionCleanupJob do
  let(:now) { Time.zone.parse("2026-08-23 16:00:00 UTC") }
  let(:account) { UserAccount.create!(phone_e164: "+5547999998511", role: "professional", status: "active") }
  let(:profile) { ProfessionalProfile.create!(user_account: account, display_name: "Ana Souza") }
  let(:storage) { instance_double(LocalDiskStorage, delete: nil) }

  it "deletes unattached media after thirty days but preserves recent uploads" do
    old_upload = create_upload("old")
    recent_upload = create_upload("recent")
    old_upload.update_columns(updated_at: now - 31.days)
    recent_upload.update_columns(updated_at: now - 29.days)

    described_class.perform_now(now:, storage:)

    expect(MediaUpload.exists?(old_upload.id)).to be(false)
    expect(MediaUpload.exists?(recent_upload.id)).to be(true)
    expect(storage).to have_received(:delete).with(scope: :private, key: old_upload.quarantine_key)
    expect(storage).not_to have_received(:delete).with(scope: :private, key: recent_upload.quarantine_key)
  end

  it "preserves an old upload while an adjustment receipt references it" do
    quote = ProfessionalQuoteWriter.new.call(
      profile:,
      attributes: {
        customer: {
          id: nil,
          name: "Marina Cliente",
          whatsapp_e164: "+5547999918511",
          email: nil
        },
        service_description: "Pintura",
        discount_amount: 0,
        valid_until: Date.current + 7.days,
        items: [{description: "Pintura", quantity: 1, unit: "serviço", unit_price: 100}],
        customer_supplied_materials: []
      }
    )
    service_job = ServiceJob.create!(quote:, status: "approved")
    adjustment = service_job.service_adjustments.create!(adjustment_number: 1, title: "Material")
    item = adjustment.service_adjustment_items.create!(
      kind: "material_reimbursement",
      description: "Tinta",
      quantity: 1,
      unit: "lata",
      unit_price: 100,
      sort_order: 0
    )
    upload = MediaUpload.create!(
      professional_profile: profile,
      purpose: "service_adjustment_receipt",
      state: "attached",
      declared_content_type: "image/jpeg",
      declared_byte_size: 100,
      sanitized_content_type: "image/jpeg",
      sanitized_byte_size: 100,
      width: 640,
      height: 480,
      quarantine_key: "quarantine/#{profile.id}/receipt",
      sanitized_key: "sanitized/#{profile.id}/receipt.jpg",
      authorization_expires_at: now - 40.days,
      attached_at: now - 40.days,
      updated_at: now - 40.days
    )
    item.create_service_adjustment_receipt!(
      media_upload: upload,
      private_key: upload.sanitized_key,
      content_type: upload.sanitized_content_type,
      byte_size: upload.sanitized_byte_size,
      width: upload.width,
      height: upload.height,
      attached_at: now - 40.days
    )

    described_class.perform_now(now:, storage:)

    expect(MediaUpload.exists?(upload.id)).to be(true)
    expect(storage).not_to have_received(:delete).with(scope: :private, key: upload.sanitized_key)
  end

  private

  def create_upload(label)
    MediaUpload.create!(
      professional_profile: profile,
      purpose: "portfolio_image",
      state: "failed",
      failure_code: "invalid_signature",
      declared_content_type: "image/jpeg",
      declared_byte_size: 100,
      quarantine_key: "quarantine/#{profile.id}/#{label}",
      authorization_expires_at: now - 40.days
    )
  end
end
