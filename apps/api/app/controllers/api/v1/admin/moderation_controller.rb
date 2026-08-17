# frozen_string_literal: true

module Api
  module V1
    module Admin
      class ModerationController < ModerationBaseController
        def index
          result = ModerationQueueQuery.new.call(
            type: params[:type],
            status: params[:status],
            search: params[:search],
            page: params[:page],
            per_page: params[:per_page]
          )
          render json: {data: result, request_id: Current.request_id}
        rescue ModerationQueueQuery::Invalid => error
          render_api_error(
            code: "validation_failed",
            message: "Revise os filtros da fila.",
            status: :unprocessable_entity,
            field_errors: error.field_errors
          )
        end
      end
    end
  end
end
