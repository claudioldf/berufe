# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Foundation probe jobs", type: :request do
  include ActiveJob::TestHelper

  it "enqueues a probe with the validated web request ID" do
    post "/foundation/probe_jobs", headers: {"X-Request-Id" => "browser-request_123"}

    expect(response).to have_http_status(:accepted)
    expect(enqueued_jobs.last.fetch("correlation_id")).to eq("browser-request_123")
    expect(response.parsed_body.fetch("job_id")).to be_present
  end

  it "replaces an unsafe inbound request ID before enqueueing" do
    post "/foundation/probe_jobs", headers: {"X-Request-Id" => "unsafe phone +5547999999999"}

    correlation_id = enqueued_jobs.last.fetch("correlation_id")
    expect(correlation_id).to match(/\A[0-9a-f-]{36}\z/)
    expect(correlation_id).not_to include("5547")
  end

  it "does not expose the dashboard without an authenticated admin MFA session" do
    get "/admin/jobs"

    expect(response).to have_http_status(:not_found)
  end
end
