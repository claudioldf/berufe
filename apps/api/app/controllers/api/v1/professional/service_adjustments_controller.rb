# frozen_string_literal: true

module Api
  module V1
    module Professional
      class ServiceAdjustmentsController < BaseController
        before_action :prevent_caching
        before_action :authenticate_application_session!

        def create
          service_job = owned_service_job!
          authorize service_job, :update?
          ProfessionalServiceAdjustmentWriter.new.call(
            service_job:,
            attributes: adjustment_params.to_h.deep_symbolize_keys
          )
          render json: service_job_response(service_job.reload), status: :created
        rescue ProfessionalServiceAdjustmentWriter::Invalid => error
          render_adjustment_errors(error)
        rescue ProfessionalServiceAdjustmentWriter::Unavailable
          render_unavailable
        end

        def update
          service_job = owned_service_job!
          authorize service_job, :update?
          adjustment = owned_adjustment!(service_job)
          ProfessionalServiceAdjustmentWriter.new.call(
            service_job:,
            adjustment:,
            attributes: adjustment_params.to_h.deep_symbolize_keys
          )
          render json: service_job_response(service_job.reload)
        rescue ProfessionalServiceAdjustmentWriter::Invalid => error
          render_adjustment_errors(error)
        rescue ProfessionalServiceAdjustmentWriter::Stale
          render_stale
        rescue ProfessionalServiceAdjustmentWriter::Unavailable
          render_unavailable
        end

        def share
          service_job = owned_service_job!
          authorize service_job, :update?
          result = ProfessionalServiceAdjustmentSharer.new.call(
            adjustment: owned_adjustment!(service_job),
            method: params.dig(:share, :method)
          )
          render json: {
            data: {
              service_job: ProfessionalServiceJobSerializer.new(service_job.reload),
              share_url: result.share_url,
              whatsapp_url: result.whatsapp_url
            },
            request_id: Current.request_id
          }
        rescue ProfessionalServiceAdjustmentSharer::InvalidMethod
          render_api_error(
            code: "validation_failed",
            message: "Revise os dados de compartilhamento.",
            status: :unprocessable_entity,
            field_errors: {method: ["não é válido"]}
          )
        rescue ProfessionalServiceAdjustmentSharer::Unavailable
          render_unavailable
        end

        def cancel
          service_job = owned_service_job!
          authorize service_job, :update?
          ProfessionalServiceAdjustmentCanceller.new.call(adjustment: owned_adjustment!(service_job))
          render json: service_job_response(service_job.reload)
        rescue ProfessionalServiceAdjustmentCanceller::Unavailable
          render_unavailable
        end

        private

        def owned_service_job!
          policy_scope(ServiceJob).find(params[:service_job_id])
        end

        def owned_adjustment!(service_job)
          service_job.service_adjustments.find(params[:id])
        end

        def adjustment_params
          params.require(:adjustment).permit(
            :revision,
            :title,
            :description,
            :schedule_impact,
            :incurred_on,
            items: %i[kind description quantity unit unit_price media_upload_id]
          )
        end

        def service_job_response(service_job)
          {
            data: {service_job: ProfessionalServiceJobSerializer.new(service_job)},
            request_id: Current.request_id
          }
        end

        def render_adjustment_errors(error)
          render_api_error(
            code: "validation_failed",
            message: "Revise os dados do ajuste.",
            status: :unprocessable_entity,
            field_errors: error.field_errors
          )
        end

        def render_stale
          render_api_error(
            code: "service_adjustment_stale",
            message: "Este ajuste mudou. Atualize a página antes de continuar.",
            status: :conflict
          )
        end

        def render_unavailable
          render_api_error(
            code: "service_adjustment_transition_unavailable",
            message: "Esta etapa do ajuste não está mais disponível.",
            status: :conflict
          )
        end
      end
    end
  end
end
