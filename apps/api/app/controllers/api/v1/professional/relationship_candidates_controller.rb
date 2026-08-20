# frozen_string_literal: true

module Api
  module V1
    module Professional
      class RelationshipCandidatesController < BaseController
        before_action :prevent_caching
        before_action :authenticate_application_session!

        def index
          initiator = Current.user_account.professional_profile
          raise ActiveRecord::RecordNotFound unless initiator

          authorize initiator, :update?
          candidates = ProfessionalRelationshipCandidateQuery.new.call(
            initiator:,
            query: params[:query]
          )
          render json: {
            data: {
              candidates: candidates.map do |profile|
                ProfessionalRelationshipCandidateSerializer.new(profile).as_json
              end
            },
            request_id: Current.request_id
          }
        rescue ProfessionalRelationshipCandidateQuery::Invalid => error
          render_api_error(
            code: "validation_failed",
            message: "Revise a busca informada.",
            status: :unprocessable_entity,
            field_errors: error.field_errors
          )
        end
      end
    end
  end
end
