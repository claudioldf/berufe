# frozen_string_literal: true

require "rails_helper"

RSpec.describe Berufe::BugsnagPrivacy do
  let(:event_class) do
    Class.new do
      attr_accessor :metadata, :context, :user, :breadcrumbs, :session

      def initialize(metadata:, context:, user:, breadcrumbs:, session:)
        @metadata = metadata
        @context = context
        @user = user
        @breadcrumbs = breadcrumbs
        @session = session
      end

      def clear_metadata(section)
        metadata.delete(section)
        metadata.delete(section.to_s)
      end

      def add_metadata(section, values)
        metadata[section] = values
      end

      def set_user(*)
        self.user = {}
      end
    end
  end

  it "retains only a validated request id and normalized execution context" do
    event = event_class.new(
      metadata: {
        request: {requestId: "request-123", url: "https://api.example.test/private?token=secret", body: {phone: "+55"}},
        active_job: {job_name: "AuthenticationRecordsCleanupJob", arguments: ["private"]},
        session: {token: "private"}
      },
      context: "api/v1/sessions#create",
      user: {id: "127.0.0.1"},
      breadcrumbs: ["private"],
      session: {id: "private"}
    )

    result = Current.set(request_id: "request-123") { described_class.call(event) }

    expect(result).to be(true)
    expect(event.metadata).to eq(
      diagnostics: {
        request_id: "request-123",
        context: "api/v1/sessions#create",
        job_class: "AuthenticationRecordsCleanupJob"
      }
    )
    expect(event.user).to eq({})
    expect(event.breadcrumbs).to eq([])
    expect(event.session).to be_nil
  end

  it "drops malformed identifiers and request paths that could contain tokens" do
    event = event_class.new(
      metadata: {request: {requestId: "not valid"}},
      context: "GET /quotes/private-token",
      user: {},
      breadcrumbs: [],
      session: nil
    )

    described_class.call(event)

    expect(event.metadata).to be_empty
  end
end
