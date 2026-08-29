# frozen_string_literal: true

class DataErasureRequestSerializer
  COMPLETION_WINDOW = 30.days

  def initialize(request_record)
    @request_record = request_record
  end

  def as_json(*)
    {
      reference: request_record.id,
      status: public_status,
      requested_at: request_record.requested_at,
      unpublished_at: request_record.unpublished_at,
      completion_deadline_at: request_record.requested_at + COMPLETION_WINDOW,
      completed_at: request_record.completed_at
    }
  end

  private

  attr_reader :request_record

  def public_status
    (request_record.status == "failed") ? "retrying" : request_record.status
  end
end
