# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Application session configuration" do
  it "uses the documented five-minute activity-write throttle" do
    expect(Rails.configuration.x.berufe.session_activity_write_interval_seconds).to eq(300)
  end
end
