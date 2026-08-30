# frozen_string_literal: true

module Api
  module V1
    module Professional
      class ServiceJobsController < BaseController
        before_action :prevent_caching
        before_action :authenticate_application_session!

        def index
          authorize ServiceJob, :index?
          jobs = policy_scope(ServiceJob)
            .includes(:customer_recommendation_request, quote: :customer)
            .order(updated_at: :desc, id: :desc)
          render json: {
            data: {service_jobs: jobs.map { |job| ProfessionalServiceJobSerializer.new(job) }},
            request_id: Current.request_id
          }
        end

        def show
          job = owned_service_job!
          authorize job, :show?
          render json: service_job_response(job)
        end

        def request_completion
          job = owned_service_job!
          authorize job, :update?
          result = ProfessionalServiceJobCompletionRequester.new.call(service_job: job)
          render json: {
            data: {
              service_job: ProfessionalServiceJobSerializer.new(result.service_job),
              share_url: result.share_url,
              whatsapp_url: result.whatsapp_url
            },
            request_id: Current.request_id
          }
        rescue ProfessionalServiceJobCompletionRequester::Unavailable
          render_unavailable
        end

        def complete
          job = owned_service_job!
          authorize job, :update?
          job = ProfessionalServiceJobCompleter.new.call(service_job: job)
          render json: service_job_response(job)
        rescue ProfessionalServiceJobCompleter::Unavailable
          render_unavailable
        end

        def cancel
          job = owned_service_job!
          authorize job, :update?
          job = ProfessionalServiceJobCanceller.new.call(
            service_job: job,
            reason: params.dig(:cancellation, :reason)
          )
          render json: service_job_response(job)
        rescue ProfessionalServiceJobCanceller::Invalid => error
          render_api_error(
            code: "validation_failed",
            message: "Revise o cancelamento.",
            status: :unprocessable_entity,
            field_errors: error.field_errors
          )
        rescue ProfessionalServiceJobCanceller::Unavailable
          render_unavailable
        end

        private

        def owned_service_job!
          policy_scope(ServiceJob).find(params[:id])
        end

        def service_job_response(job)
          {
            data: {service_job: ProfessionalServiceJobSerializer.new(job)},
            request_id: Current.request_id
          }
        end

        def render_unavailable
          render_api_error(
            code: "service_job_transition_unavailable",
            message: "Esta etapa do serviço não está mais disponível.",
            status: :conflict
          )
        end
      end
    end
  end
end
