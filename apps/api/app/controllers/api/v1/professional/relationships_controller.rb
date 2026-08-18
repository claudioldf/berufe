# frozen_string_literal: true

module Api
  module V1
    module Professional
      class RelationshipsController < BaseController
        before_action :prevent_caching
        before_action :authenticate_application_session!

        def create
          initiator = owned_profile!

          authorize initiator, :update?
          relationship = ProfessionalRelationshipRequester.new.call(
            initiator:,
            **relationship_params
          )
          render json: {
            data: {relationship: ProfessionalRelationshipSerializer.new(relationship)},
            request_id: Current.request_id
          }, status: :created,
            location: "/api/v1/professional/relationships/#{relationship.id}"
        rescue ProfessionalRelationshipRequester::Ineligible
          raise Pundit::NotAuthorizedError
        rescue ProfessionalRelationshipRequester::Duplicate
          render_api_error(
            code: "relationship_conflict",
            message: "Esta solicitação de relação já existe.",
            status: :conflict
          )
        rescue ProfessionalRelationshipRequester::Invalid => error
          render_api_error(
            code: "validation_failed",
            message: "Revise os dados da relação profissional.",
            status: :unprocessable_entity,
            field_errors: error.field_errors
          )
        end

        def respond
          recipient = owned_profile!
          relationship = recipient.received_relationships.find(params[:id])
          relationship = ProfessionalRelationshipResponder.new.call(
            relationship:,
            recipient:,
            response: params.require(:response)
          )
          render json: {
            data: {relationship: ProfessionalRelationshipSerializer.new(relationship)},
            request_id: Current.request_id
          }
        rescue ProfessionalRelationshipResponder::Conflict
          render_api_error(
            code: "relationship_conflict",
            message: "Esta solicitação já recebeu uma resposta.",
            status: :conflict
          )
        rescue ProfessionalRelationshipResponder::Invalid => error
          render_api_error(
            code: "validation_failed",
            message: "Revise a resposta da relação profissional.",
            status: :unprocessable_entity,
            field_errors: error.field_errors
          )
        end

        private

        def relationship_params
          params.require(:relationship).permit(
            :recipient_professional_id,
            :relationship_type,
            :context_note
          ).to_h.symbolize_keys
        end

        def owned_profile!
          profile = Current.user_account.professional_profile
          raise ActiveRecord::RecordNotFound unless profile

          authorize profile, :update?
          profile
        end
      end
    end
  end
end
