# frozen_string_literal: true

require "rails_helper"

RSpec.describe DataErasureRecoveryJob do
  it "re-enqueues requested and failed erasures without touching completed requests" do
    requested = create_request(status: "requested", phone: "+5547999998511")
    failed = create_request(status: "failed", phone: "+5547999998512")
    completed = create_request(status: "completed", phone: "+5547999998513")

    described_class.perform_now

    expect(ProfessionalDataErasureJob).to have_been_enqueued.with(requested.id)
    expect(ProfessionalDataErasureJob).to have_been_enqueued.with(failed.id)
    expect(ProfessionalDataErasureJob).not_to have_been_enqueued.with(completed.id)
  end

  private

  def create_request(status:, phone:)
    account = UserAccount.create!(phone_e164: phone, role: "professional", status: "suspended")
    DataErasureRequest.create!(
      target_user_account_id: (account.id unless status == "completed"),
      subject_digest: PrivacySubjectDigest.call(phone),
      ticket_reference: "SUP-#{phone.last(4)}",
      status:,
      verification_method: "recent_sms_otp",
      requested_at: Time.current,
      verified_at: Time.current,
      unpublished_at: Time.current,
      completed_at: (Time.current if status == "completed"),
      retained_until: 5.years.from_now
    )
  end
end
