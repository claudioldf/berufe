# frozen_string_literal: true

require "rails_helper"

RSpec.describe SharedServiceAdjustmentReceiptReader do
  let(:account) do
    UserAccount.create!(phone_e164: "+5547999997703", role: "professional", status: "active")
  end
  let(:profile) { ProfessionalProfile.create!(user_account: account, display_name: "Ana Souza") }
  let(:quote) do
    ProfessionalQuoteWriter.new.call(
      profile:,
      attributes: {
        customer: {
          id: nil,
          name: "Marina Cliente",
          whatsapp_e164: "+5547999912703",
          email: nil
        },
        service_description: "Pintura",
        discount_amount: 0,
        valid_until: Date.current + 7.days,
        items: [{description: "Pintura", quantity: 1, unit: "serviço", unit_price: 100}],
        customer_supplied_materials: []
      }
    )
  end

  it "reads only a sanitized receipt related to the bearer service" do
    make_profile_publicly_eligible(profile)
    share = ProfessionalQuoteSharer.new.call(quote:, method: "copy")
    token = URI(share.share_url).path.split("/").last
    service_job = SharedQuoteDecisionRecorder.new.call(
      token:,
      decision: "approve",
      revision: quote.reload.lock_version,
      terms_accepted: true,
      message: nil
    )[:service_job]
    upload = MediaUpload.create!(
      professional_profile: profile,
      purpose: "service_adjustment_receipt",
      state: "attached",
      declared_content_type: "image/jpeg",
      declared_byte_size: 100,
      actual_content_type: "image/jpeg",
      sanitized_content_type: "image/jpeg",
      actual_byte_size: 100,
      sanitized_byte_size: 100,
      width: 640,
      height: 480,
      quarantine_key: "quarantine/#{profile.id}/#{SecureRandom.uuid}",
      sanitized_key: "sanitized/#{profile.id}/#{SecureRandom.uuid}.jpg",
      authorization_expires_at: 5.minutes.from_now,
      uploaded_at: 2.minutes.ago,
      processed_at: 1.minute.ago,
      attached_at: Time.current
    )
    adjustment = service_job.service_adjustments.create!(
      adjustment_number: 1,
      status: "awaiting_response",
      title: "Material",
      shared_at: Time.current
    )
    item = adjustment.service_adjustment_items.create!(
      kind: "material_reimbursement",
      description: "Tinta",
      quantity: 1,
      unit: "lata",
      unit_price: 100,
      sort_order: 0
    )
    receipt = item.create_service_adjustment_receipt!(
      media_upload: upload,
      private_key: upload.sanitized_key,
      content_type: upload.sanitized_content_type,
      byte_size: upload.sanitized_byte_size,
      width: upload.width,
      height: upload.height,
      attached_at: Time.current
    )
    storage = instance_double(LocalDiskStorage, read: "safe-image")
    validator = instance_double(RegeneratedImageValidator, call: true)

    result = described_class.new(storage:, validator:).call(token:, receipt_id: receipt.id)

    expect(result).to have_attributes(body: "safe-image", content_type: "image/jpeg")
    expect(storage).to have_received(:read).with(scope: :private, key: upload.sanitized_key)
    expect do
      described_class.new(storage:, validator:).call(token:, receipt_id: SecureRandom.uuid)
    end.to raise_error(described_class::NotFound)

    adjustment.update!(status: "draft", shared_at: nil)
    expect do
      described_class.new(storage:, validator:).call(token:, receipt_id: receipt.id)
    end.to raise_error(described_class::NotFound)
  end
end
