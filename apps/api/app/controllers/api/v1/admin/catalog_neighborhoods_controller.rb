# frozen_string_literal: true

module Api
  module V1
    module Admin
      class CatalogNeighborhoodsController < CatalogBaseController
        def create
          catalog = catalog_management.create_neighborhood(neighborhood_attributes(include_code: true))
          render_catalog(catalog, status: :created)
        end

        def update
          catalog = catalog_management.update_neighborhood(params[:code], neighborhood_attributes)
          render_catalog(catalog)
        end

        def reorder
          catalog = catalog_management.reorder_neighborhoods(params.require(:codes))
          render_catalog(catalog)
        end

        private

        def neighborhood_attributes(include_code: false)
          permitted = params.permit(:name, :code, :stateCode, :city, :isActive)
          require_neighborhood_create_fields! if include_code
          attributes = {}
          attributes[:name] = permitted[:name] if permitted.key?(:name)
          attributes[:code] = permitted[:code] if include_code
          attributes[:state_code] = permitted[:stateCode] if permitted.key?(:stateCode)
          attributes[:city] = permitted[:city] if permitted.key?(:city)
          attributes[:is_active] = permitted[:isActive] if permitted.key?(:isActive)
          raise ActionController::ParameterMissing, :neighborhood if attributes.empty?

          attributes
        end

        def require_neighborhood_create_fields!
          %i[name code stateCode city].each { |field| params.require(field) }
        end
      end
    end
  end
end
