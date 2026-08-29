# frozen_string_literal: true

class DataErasureRecoveryJob < ApplicationJob
  queue_as :default

  def perform
    DataErasureRequest.where(status: %w[requested failed]).find_each do |request_record|
      ProfessionalDataErasureJob.perform_later(request_record.id)
    end
  end
end
