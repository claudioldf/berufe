# frozen_string_literal: true

require "rails_helper"

RSpec.describe Berufe::Reporting do
  it "falls back to six calendar months when a running process lacks the new setting" do
    settings = ActiveSupport::OrderedOptions.new
    now = Time.zone.parse("2026-08-26 12:00:00")

    expect(described_class.llm_search_audit_retention_months(settings:)).to eq(6)
    expect(described_class.llm_search_audit_window_start(now, settings:)).to eq(now - 6.months)
  end

  it "honors an explicitly configured retention period" do
    settings = ActiveSupport::OrderedOptions.new
    settings.llm_search_audit_retention_months = 3
    now = Time.zone.parse("2026-08-26 12:00:00")

    expect(described_class.llm_search_audit_window_start(now, settings:)).to eq(now - 3.months)
  end
end
