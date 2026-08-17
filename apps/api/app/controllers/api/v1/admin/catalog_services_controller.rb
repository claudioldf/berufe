# frozen_string_literal: true

module Api
  module V1
    module Admin
      class CatalogServicesController < CatalogBaseController
        def create
          catalog = catalog_management.create_service(service_attributes(include_slug: true))
          render_catalog(catalog, status: :created)
        end

        def update
          catalog = catalog_management.update_service(params[:id], service_attributes)
          render_catalog(catalog)
        end

        def reorder
          catalog = catalog_management.reorder_services(params.require(:ids))
          render_catalog(catalog)
        end

        private

        def service_attributes(include_slug: false)
          permitted = params.permit(:name, :slug, :categorySlug, :description, :isActive)
          require_service_create_fields! if include_slug
          attributes = {}
          attributes[:name] = permitted[:name] if permitted.key?(:name)
          attributes[:slug] = permitted[:slug] if include_slug
          attributes[:category_slug] = permitted[:categorySlug] if permitted.key?(:categorySlug)
          attributes[:description] = permitted[:description] if permitted.key?(:description)
          attributes[:is_active] = permitted[:isActive] if permitted.key?(:isActive)
          raise ActionController::ParameterMissing, :service if attributes.empty?

          attributes
        end

        def require_service_create_fields!
          %i[name slug categorySlug description].each { |field| params.require(field) }
        end
      end
    end
  end
end
