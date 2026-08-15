# frozen_string_literal: true

require "rails_helper"

RSpec.describe BrazilianPhoneNumber do
  it "normalizes national, formatted, and E.164 Brazilian mobile numbers" do
    expect(described_class.normalize("(47) 99999-1111")).to eq("+5547999991111")
    expect(described_class.normalize("47 99999-1111")).to eq("+5547999991111")
    expect(described_class.normalize("+55 47 99999-1111")).to eq("+5547999991111")
  end

  it "rejects landlines, unknown area codes, letters, and foreign numbers" do
    invalid_numbers = ["(47) 3333-1111", "(10) 99999-1111", "47 99999-ABCD", "+1 202 555 0100"]

    invalid_numbers.each do |number|
      expect { described_class.normalize(number) }.to raise_error(described_class::Invalid)
    end
  end
end
