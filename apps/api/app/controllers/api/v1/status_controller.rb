# frozen_string_literal: true

module Api
  module V1
    class StatusController < BaseController
      def show
        ActiveRecord::Base.connection.select_value("SELECT 1")
        render json: {
          data: {service: "berufe-api", status: "ok"},
          request_id: Current.request_id
        }
      rescue ActiveRecord::ActiveRecordError => error
        report_service_error(error)
        render_api_error(
          code: "service_unavailable",
          message: "Serviço temporariamente indisponível.",
          status: :service_unavailable
        )
      end
    end
  end
end
