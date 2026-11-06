# frozen_string_literal: true

# Tells a professional their identity was approved: by e-mail when they have
# one, otherwise by SMS. Each channel is its own delivery job.
class IdentityApprovalNotifier
  def initialize(email_job: ProfessionalIdentityApprovedEmailJob, sms_job: ProfessionalIdentityApprovedSmsJob)
    @email_job = email_job
    @sms_job = sms_job
  end

  def call(request_record)
    account = request_record.professional_profile.user_account
    return unless account.active?

    if account.email.present?
      email_job.perform_later(request_record.id)
    elsif account.phone_e164.present?
      sms_job.perform_later(request_record.id)
    end
  end

  private

  attr_reader :email_job, :sms_job
end
