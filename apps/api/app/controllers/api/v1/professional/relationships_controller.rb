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
          relationship = recipient.received_relationships.active.find(params[:id])
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

        def destroy
          profile = owned_profile!
          relationship = ProfessionalRelationship.active
            .where(
              "initiator_professional_id = :id OR recipient_professional_id = :id",
              id: profile.id
            )
            .find(params[:id])
          ProfessionalRelationshipRemover.new.call(relationship:, professional: profile)
          render json: workspace_response(profile.reload)
        rescue ProfessionalRelationshipRemover::NotRemovable
          raise ActiveRecord::RecordNotFound
        end

        private

        def relationship_params
          params.require(:relationship).permit(
            :relationship_type,
            :context_note,
            target: [
              :type,
              :professional_profile_id,
              :name,
              :phone,
              :contact_publication_attested,
              {service_ids: [], coverage: [:all_joinville, {neighborhood_codes: []}]}
            ]
          ).to_h.deep_symbolize_keys
        end

        def owned_profile!
          profile = Current.user_account.professional_profile
          raise ActiveRecord::RecordNotFound unless profile

          authorize profile, :update?
          profile
        end

        def workspace_response(profile)
          {
            data: ProfessionalWorkspaceSerializer.new(profile),
            request_id: Current.request_id
          }
        end
      end
    end
  end
end
