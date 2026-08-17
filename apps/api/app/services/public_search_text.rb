# frozen_string_literal: true

class PublicSearchText
  def self.normalize(value)
    I18n.transliterate(value.to_s)
      .downcase
      .gsub(/[^a-z0-9]+/, " ")
      .squish
  end
end
