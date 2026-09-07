# frozen_string_literal: true

class ProfessionalServiceAdjustmentCanceller
  class Unavailable < StandardError; end

  def call(adjustment:)
    adjustment.with_lock do
      raise Unavailable unless adjustment.editable?

      adjustment.update!(
        status: "cancelled",
        customer_decision_message: nil,
        terms_accepted_at: nil
      )
    end
    adjustment.reload
  end
end
