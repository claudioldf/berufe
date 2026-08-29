# frozen_string_literal: true

module Api
  module V1
    class DataErasureRequestsController < BaseController
      before_action :prevent_caching

      def show
        token = params[:status_token].to_s
        raise ActiveRecord::RecordNotFound unless DataErasureStatusToken.valid?(token)

        request_record = DataErasureRequest.find_by!(
          status_token_hash: DataErasureStatusToken.digest(token)
        )
        render json: {
          data: DataErasureRequestSerializer.new(request_record),
          request_id: Current.request_id
        }
      rescue ActiveRecord::ConnectionNotEstablished, ActiveRecord::StatementInvalid => error
        report_service_error(error)
        render_api_error(
          code: "erasure_status_unavailable",
          message: "Não foi possível consultar a solicitação agora.",
          status: :service_unavailable
        )
      end
    end
  end
end
