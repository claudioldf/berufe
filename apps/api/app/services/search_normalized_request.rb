# frozen_string_literal: true

# Builds the short first-person contact sentence used when a resolver cannot
# write one itself (the fake adapter and JEV, which only classifies).
class SearchNormalizedRequest
  def self.call(service_name:, location_name:, state_code:)
    return if service_name.to_s.strip.empty?

    "Eu preciso de #{service_name.downcase} em #{location_name}, #{state_code}."
      .first(WhatsappRequestMessageBuilder::MAXIMUM_REQUEST_LENGTH)
  end
end
