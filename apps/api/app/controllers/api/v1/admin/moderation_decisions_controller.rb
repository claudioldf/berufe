# frozen_string_literal: true

module Api
  module V1
    module Admin
      class ModerationDecisionsController < ModerationBaseController
        def create
          ModerationDecision.new.call(
            target_type: params[:target_type],
            target_id: params[:target_id],
            **decision_params.to_h.symbolize_keys
          )
          result = ModerationQueueQuery.new.call(
            status: params[:status],
            search: params[:search],
            page: params[:page],
            per_page: params[:per_page]
          )
          render json: {data: result, request_id: Current.request_id}
        rescue ModerationDecision::Invalid => error
          render_api_error(
            code: "validation_failed",
            message: "Revise a decisão informada.",
            status: :unprocessable_entity,
            field_errors: error.field_errors
          )
        rescue ModerationDecision::Conflict
          render_api_error(
            code: "moderation_conflict",
            message: "O item mudou. Atualize a fila e tente novamente.",
            status: :conflict
          )
        end

        private

        def decision_params
          params.require(:decision).permit(:action, :reason, :note, :identity_match_confirmed)
        end
      end
    end
  end
end
