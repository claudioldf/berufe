# frozen_string_literal: true

module Api
  module V1
    class CatalogsController < BaseController
      def show
        render json: {
          data: {
            categories: ServiceCategory.active.ordered.map { |category| serialize_category(category) },
            services: Service.publicly_active.includes(:category).ordered.map { |service| serialize_service(service) },
            neighborhoods: Neighborhood.active.ordered.map { |neighborhood| serialize_neighborhood(neighborhood) }
          },
          request_id: Current.request_id
        }
      rescue ActiveRecord::ActiveRecordError
        render_api_error(
          code: "service_unavailable",
          message: "Catálogo temporariamente indisponível.",
          status: :service_unavailable
        )
      end

      private

      def serialize_category(category)
        {
          id: category.id,
          slug: category.slug,
          name: category.name,
          icon: category.icon
        }
      end

      def serialize_service(service)
        {
          id: service.id,
          name: service.name,
          slug: service.slug,
          categorySlug: service.category.slug,
          icon: service.icon,
          description: service.description,
          aliases: service.aliases
        }
      end

      def serialize_neighborhood(neighborhood)
        {
          code: neighborhood.code,
          name: neighborhood.name,
          stateCode: neighborhood.state_code,
          city: neighborhood.city_code
        }
      end
    end
  end
end
