# frozen_string_literal: true

class PublicSearchEventRecorder
  Interaction = Data.define(:search_event_id, :token)

  def initialize(
    token_issuer: PublicInteractionToken.new,
    deduplicator: PublicSearchEventDeduplicator.new
  )
    @token_issuer = token_issuer
    @deduplicator = deduplicator
  end

  def call(criteria:, result_count:, subject:, query:, event: nil, now: Time.current)
    service = Service.find_by(id: criteria.service_ids.first) if criteria.service_ids.one?
    neighborhood_codes = criteria.locations.filter_map(&:neighborhood_code).uniq
    neighborhood_code = neighborhood_codes.first if neighborhood_codes.one?
    neighborhood = Neighborhood.find_by(code: neighborhood_code) if neighborhood_code
    attributes = {
      service:,
      query_text_normalized: nil,
      city_code: SearchEvent::JOINVILLE,
      neighborhood:,
      result_count:,
      reportable: true
    }
    if event
      attributes[:audit_status] = "completed"
      attributes[:parsed_response] ||= PublicSearchAuditRecorder.parsed_response(criteria)
      event.update!(attributes)
    else
      event = SearchEvent.create!(attributes)
    end
    event = deduplicator.reuse_or_claim!(
      event:,
      subject:,
      query:,
      result_count:,
      now:
    )
    token = token_issuer.issue(search_event_id: event.id, service_ids: criteria.service_ids)

    Interaction.new(search_event_id: event.id, token:)
  rescue ActiveRecord::ActiveRecordError => error
    Rails.error.report(error)
    Rails.logger.error(
      "public_search_event_recording_failed class=#{error.class} request_id=#{Current.request_id}"
    )
    nil
  end

  private

  attr_reader :deduplicator, :token_issuer
end
