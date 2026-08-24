# frozen_string_literal: true

require "rails_helper"

RSpec.describe Berufe::BugsnagHandledErrorSubscriber do
  subject(:subscriber) { described_class.new }

  it "forwards handled Rails errors to Bugsnag with the requested severity" do
    error = ActiveRecord::ConnectionNotEstablished.new("private database detail")
    report = instance_double(Bugsnag::Report)
    allow(report).to receive(:severity=)
    allow(report).to receive(:unhandled=)
    allow(Bugsnag).to receive(:notify).with(error).and_yield(report)

    subscriber.report(
      error,
      handled: true,
      severity: :error,
      context: {private_id: 123},
      source: "application"
    )

    expect(Bugsnag).to have_received(:notify).with(error)
    expect(report).to have_received(:severity=).with("error")
    expect(report).to have_received(:unhandled=).with(false)
  end

  it "leaves unhandled errors to Bugsnag's Rails and Active Job integrations" do
    allow(Bugsnag).to receive(:notify)

    subscriber.report(
      RuntimeError.new("boom"),
      handled: false,
      severity: :error,
      context: {},
      source: "application"
    )

    expect(Bugsnag).not_to have_received(:notify)
  end

  it "does not let a Bugsnag transport failure escape the error reporter" do
    allow(Bugsnag).to receive(:notify).and_raise(StandardError, "transport failed")
    allow(Rails.logger).to receive(:error)

    expect do
      subscriber.report(
        RuntimeError.new("boom"),
        handled: true,
        severity: :warning,
        context: {},
        source: "application"
      )
    end.not_to raise_error
    expect(Rails.logger).to have_received(:error).with(
      "bugsnag_handled_error_report_failed class=StandardError"
    )
  end
end
