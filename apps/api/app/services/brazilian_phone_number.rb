# frozen_string_literal: true

class BrazilianPhoneNumber
  class Invalid < StandardError; end

  VALID_AREA_CODES = %w[
    11 12 13 14 15 16 17 18 19 21 22 24 27 28 31 32 33 34 35 37 38 41 42
    43 44 45 46 47 48 49 51 53 54 55 61 62 63 64 65 66 67 68 69 71 73 74
    75 77 79 81 82 83 84 85 86 87 88 89 91 92 93 94 95 96 97 98 99
  ].freeze
  NATIONAL_MOBILE_PATTERN = /\A(?<area_code>\d{2})9\d{8}\z/
  FORMATTING_PATTERN = /[\s().-]/

  def self.normalize(input)
    candidate = input.to_s.strip
    digits = candidate.delete_prefix("+").gsub(FORMATTING_PATTERN, "")
    digits = digits.delete_prefix("55") if digits.length == 13
    match = NATIONAL_MOBILE_PATTERN.match(digits)

    raise Invalid unless match && VALID_AREA_CODES.include?(match[:area_code])

    "+55#{digits}"
  end
end
