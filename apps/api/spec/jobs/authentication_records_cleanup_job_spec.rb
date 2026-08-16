# frozen_string_literal: true

require "rails_helper"

RSpec.describe AuthenticationRecordsCleanupJob, type: :job do
  include ActiveSupport::Testing::TimeHelpers

  after { travel_back }

  it "idempotently purges only records whose operational expiry has passed" do
    now = Time.zone.parse("2026-08-15 12:00:00 UTC")
    expired_challenge = create_challenge(created_at: now - 20.minutes, expires_at: now - 10.minutes)
    active_challenge = create_challenge(created_at: now, expires_at: now + 10.minutes)
    expired_counter = create_counter(window_started_at: now - 1.day, expires_at: now)
    active_counter = create_counter(
      scope_kind: "ip",
      subject_digest: "b" * 64,
      window_started_at: now,
      expires_at: now + 1.day
    )
    account = UserAccount.create!(phone_e164: "+5547999991111", role: "professional", status: "active")
    expired_session, = ApplicationSession.issue!(user_account: account, now: now - 7.days)
    active_session, = ApplicationSession.issue!(user_account: account, now:)
    expired_admin_counter = create_admin_counter(window_started_at: now - 16.minutes)
    active_admin_counter = create_admin_counter(
      scope: "ip",
      subject_digest: "d" * 64,
      window_started_at: now - 14.minutes
    )

    2.times { described_class.perform_now(now:) }

    expect(OtpChallenge.exists?(expired_challenge.id)).to be(false)
    expect(OtpChallenge.exists?(active_challenge.id)).to be(true)
    expect(OtpRequestCounter.exists?(expired_counter.id)).to be(false)
    expect(OtpRequestCounter.exists?(active_counter.id)).to be(true)
    expect(ApplicationSession.exists?(expired_session.id)).to be(false)
    expect(ApplicationSession.exists?(active_session.id)).to be(true)
    expect(AdminLoginAttemptCounter.exists?(expired_admin_counter.id)).to be(false)
    expect(AdminLoginAttemptCounter.exists?(active_admin_counter.id)).to be(true)
  end

  it "runs on the worker's default queue" do
    expect(described_class.new.queue_name).to eq("default")
  end

  private

  def create_challenge(created_at:, expires_at:)
    travel_to(created_at) do
      OtpChallenge.issue!(
        phone_e164: "+5547999991111",
        provider_reference: SecureRandom.uuid,
        expires_at:
      ).first
    end
  end

  def create_counter(
    window_started_at:,
    expires_at:,
    scope_kind: "phone",
    subject_digest: "a" * 64
  )
    OtpRequestCounter.create!(
      scope_kind:,
      subject_digest:,
      window_started_at:,
      expires_at:,
      request_count: 1,
      last_requested_at: window_started_at
    )
  end

  def create_admin_counter(window_started_at:, scope: "email", subject_digest: "c" * 64)
    AdminLoginAttemptCounter.create!(scope:, subject_digest:, window_started_at:, attempt_count: 1)
  end
end
