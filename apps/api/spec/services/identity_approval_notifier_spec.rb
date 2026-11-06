# frozen_string_literal: true

require "rails_helper"

RSpec.describe IdentityApprovalNotifier do
  def request_for(email: nil, phone: "+5547999998301", status: "active")
    account = UserAccount.create!(role: "professional", status: "active", email:, phone_e164: phone)
    profile = ProfessionalProfile.create!(user_account: account, display_name: "Ana Souza")
    account.update_columns(status:)
    profile.verification_requests.create!(verification_type: "identity", status: "approved", submitted_at: Time.current)
  end

  it "sends only the e-mail job when the professional has an e-mail" do
    request = request_for(email: "ana@example.com")

    expect { described_class.new.call(request) }
      .to have_enqueued_job(ProfessionalIdentityApprovedEmailJob).with(request.id)
    expect { described_class.new.call(request) }.not_to have_enqueued_job(ProfessionalIdentityApprovedSmsJob)
  end

  it "falls back to the SMS job when there is no e-mail" do
    request = request_for

    expect { described_class.new.call(request) }
      .to have_enqueued_job(ProfessionalIdentityApprovedSmsJob).with(request.id)
    expect { described_class.new.call(request) }.not_to have_enqueued_job(ProfessionalIdentityApprovedEmailJob)
  end

  it "does nothing for suspended accounts" do
    request = request_for(email: "ana@example.com", status: "suspended")

    expect { described_class.new.call(request) }
      .not_to have_enqueued_job.on_queue("default")
  end
end
