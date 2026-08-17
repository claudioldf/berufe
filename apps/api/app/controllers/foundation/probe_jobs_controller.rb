# frozen_string_literal: true

module Foundation
  class ProbeJobsController < ApplicationController
    def create
      job = FoundationProbeJob.perform_later(
        probe_id: SecureRandom.uuid,
        fail_once: ActiveModel::Type::Boolean.new.cast(params[:fail_once])
      )

      render json: {job_id: job.job_id}, status: :accepted
    end
  end
end
