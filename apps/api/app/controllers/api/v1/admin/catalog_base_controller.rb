# frozen_string_literal: true

module Api
  module V1
    module Admin
      class CatalogBaseController < BaseController
        before_action :prevent_caching
        before_action :authenticate_password_admin_session!
        before_action :authorize_catalog_management!

        rescue_from ActiveRecord::ActiveRecordError, with: :render_catalog_unavailable
        rescue_from ActiveRecord::RecordInvalid, with: :render_catalog_validation_error
        rescue_from ActiveRecord::RecordNotUnique, CatalogManagement::Conflict, with: :render_catalog_conflict
        rescue_from ActiveRecord::RecordNotFound, with: :render_catalog_not_found

        private

        def catalog_management
          @catalog_management ||= CatalogManagement.new
        end

        def authorize_catalog_management!
          authorize :admin_catalog, :manage?
        end

        def render_catalog(catalog, status: :ok)
          render json: {
            data: catalog,
            request_id: Current.request_id
          }, status:
        end

        def render_catalog_validation_error(error)
          return render_catalog_conflict if uniqueness_conflict?(error.record)

          render_api_error(
            code: "validation_failed",
            message: "Revise os campos informados.",
            status: :unprocessable_entity,
            field_errors: catalog_field_errors(error.record)
          )
        end

        def uniqueness_conflict?(record)
          record.errors.details.values.flatten.any? { |detail| detail[:error] == :taken }
        end

        def render_catalog_conflict(*)
          render_api_error(
            code: "catalog_conflict",
            message: "O catálogo foi alterado. Atualize a página e tente novamente.",
            status: :conflict
          )
        end

        def render_catalog_not_found(*)
          render_api_error(
            code: "not_found",
            message: "Recurso não encontrado.",
            status: :not_found
          )
        end

        def render_catalog_unavailable(error)
          report_service_error(error)
          render_api_error(
            code: "catalog_unavailable",
            message: "Catálogo temporariamente indisponível.",
            status: :service_unavailable
          )
        end

        def catalog_field_errors(record)
          record.errors.to_hash(true).transform_keys do |field|
            {
              category: :category_slug,
              city_code: :city,
              is_active: :is_active,
              state_code: :state_code
            }.fetch(field, field)
          end
        end
      end
    end
  end
end
