# frozen_string_literal: true

class PublicSearchEventRecorder
  Interaction = Data.define(:search_event_id, :token)

  def initialize(
    sanitizer: SearchEventQuerySanitizer.new,
    token_issuer: PublicInteractionToken.new
  )
    @sanitizer = sanitizer
    @token_issuer = token_issuer
  end

  def call(raw_term:, normalized_term:, service:, neighborhood:, result_count:)
    event = SearchEvent.create!(
      service:,
      query_text_normalized: sanitizer.call(raw_term:, normalized_term:),
      city_code: SearchEvent::JOINVILLE,
      neighborhood:,
      result_count:
    )
    token = token_issuer.issue(search_event_id: event.id, service_id: service&.id)

    Interaction.new(search_event_id: event.id, token:)
  rescue ActiveRecord::ActiveRecordError => error
    Rails.logger.error(
      "public_search_event_recording_failed class=#{error.class} request_id=#{Current.request_id}"
    )
    nil
  end

  private

  attr_reader :sanitizer, :token_issuer
end
