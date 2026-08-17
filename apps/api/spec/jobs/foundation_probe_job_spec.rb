# frozen_string_literal: true

require "rails_helper"

RSpec.describe FoundationProbeJob, type: :job do
  include ActiveJob::TestHelper

  it "uses the default queue and the Rails test adapter" do
    expect(described_class.new.queue_name).to eq("default")
    expect(ActiveJob::Base.queue_adapter).to be_a(ActiveJob::QueueAdapters::TestAdapter)
  end

  it "serializes and restores the originating request ID" do
    job = Current.set(request_id: "request-123") do
      described_class.perform_later(probe_id: "probe-123")
    end
    restored_job = described_class.deserialize(job.serialize)

    expect(job.correlation_id).to eq("request-123")
    expect(restored_job.correlation_id).to eq("request-123")
  end

  it "fails once and then becomes safe to retry" do
    job = described_class.new
    job.executions = 1
    expect { job.perform(probe_id: "probe-123", fail_once: true) }
      .to raise_error(described_class::ProbeFailure)

    job.executions = 2
    expect { job.perform(probe_id: "probe-123", fail_once: true) }.not_to raise_error
  end
end
