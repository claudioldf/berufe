# frozen_string_literal: true

require "rails_helper"

RSpec.describe AdminMfaConstraint do
  Session = Data.define(:active, :admin, :mfa_current) do
    alias_method :active?, :active
    alias_method :admin?, :admin
    alias_method :mfa_current?, :mfa_current
  end

  it "allows only an active administrator session with current MFA" do
    request = instance_double(ActionDispatch::Request, env: {
      described_class::SESSION_ENV_KEY => Session.new(true, true, true)
    })

    expect(described_class.new.matches?(request)).to be(true)
  end

  it "rejects missing, inactive, non-admin, and stale-MFA sessions" do
    sessions = [nil, Session.new(false, true, true), Session.new(true, false, true), Session.new(true, true, false)]

    sessions.each do |session|
      request = instance_double(ActionDispatch::Request, env: {described_class::SESSION_ENV_KEY => session})
      expect(described_class.new.matches?(request)).to be_falsey
    end
  end
end
