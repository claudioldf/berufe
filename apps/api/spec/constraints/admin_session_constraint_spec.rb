# frozen_string_literal: true

require "rails_helper"

RSpec.describe AdminSessionConstraint do
  let(:account_class) do
    Data.define(:admin) do
      alias_method :admin?, :admin
    end
  end
  let(:session_class) { Data.define(:user_account, :authentication_method, :impersonating) { alias_method :impersonating?, :impersonating } }
  let(:request_env) { {} }
  let(:request) do
    instance_double(
      ActionDispatch::Request,
      cookies: {ApplicationSession::COOKIE_NAME => "opaque-token"},
      env: request_env
    )
  end

  it "allows a locally authenticated administrator password session" do
    session = session_class.new(account_class.new(true), "password", false)
    allow_authenticator(session)

    expect(described_class.new.matches?(request)).to be(true)
    expect(request_env.fetch(described_class::SESSION_ENV_KEY)).to eq(session)
  end

  it "rejects missing, professional, and non-password sessions" do
    sessions = [
      nil,
      session_class.new(account_class.new(false), "sms_otp", false),
      session_class.new(account_class.new(true), "sms_otp", false),
      session_class.new(account_class.new(true), "password", true)
    ]

    sessions.each do |session|
      allow_authenticator(session)
      expect(described_class.new.matches?(request)).to be(false)
    end
  end

  it "fails closed when session persistence is unavailable" do
    authenticator = instance_double(ApplicationSessionAuthenticator)
    allow(ApplicationSessionAuthenticator).to receive(:new).and_return(authenticator)
    allow(authenticator).to receive(:call).and_raise(ActiveRecord::ConnectionNotEstablished)

    expect(described_class.new.matches?(request)).to be(false)
  end

  private

  def allow_authenticator(session)
    authenticator = instance_double(ApplicationSessionAuthenticator, call: session)
    allow(ApplicationSessionAuthenticator).to receive(:new).and_return(authenticator)
  end
end
