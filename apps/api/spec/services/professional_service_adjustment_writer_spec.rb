# frozen_string_literal: true

require "rails_helper"

RSpec.describe ProfessionalServiceAdjustmentWriter do
  let(:account) do
    UserAccount.create!(phone_e164: "+5547999997702", role: "professional", status: "active")
  end
  let(:profile) { ProfessionalProfile.create!(user_account: account, display_name: "Ana Souza") }
  let(:quote) do
    ProfessionalQuoteWriter.new.call(
      profile:,
      attributes: {
        customer: {
          id: nil,
          name: "Marina Cliente",
          whatsapp_e164: "+5547999912702",
          email: nil
        },
        pricing_mode: "fixed_price",
        fixed_price_amount: 100,
        service_description: "Reparo",
        discount_amount: 0,
        valid_until: Date.current + 7.days,
        items: [],
        customer_supplied_materials: []
      }
    )
  end
  let(:service_job) { ServiceJob.create!(quote:, status: "approved") }

  it "attaches an optional sanitized receipt only to a reimbursement item" do
    upload = MediaUpload.create!(
      professional_profile: profile,
      purpose: "service_adjustment_receipt",
      state: "processed",
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
      uploaded_at: 1.minute.ago,
      processed_at: Time.current
    )

    adjustment = described_class.new.call(
      service_job:,
      attributes: {
        title: "Compra de material",
        items: [
          {
            kind: "material_reimbursement",
            description: "Tinta",
            quantity: 1,
            unit: "lata",
            unit_price: 80,
            media_upload_id: upload.id
          }
        ]
      }
    )

    expect(adjustment.service_adjustment_items.sole.service_adjustment_receipt).to have_attributes(
      media_upload: upload,
      private_key: upload.sanitized_key
    )
    expect(upload.reload).to be_attached
  end
end
