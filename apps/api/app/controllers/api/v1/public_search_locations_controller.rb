# frozen_string_literal: true

module Api
  module V1
    class PublicSearchLocationsController < BaseController
      def show
        prevent_caching
        result = PublicSearchLocationResolver.new.call(
          ip_address: VisitorIpResolver.new.call(request)
        )

        render json: {
          data: serialize(result),
          request_id: Current.request_id
        }
      end

      private

      def serialize(result)
        {
          city_code: result.location.city_code,
          state_code: result.location.state_code,
          city: result.location.city,
          state_slug: result.location.state_slug,
          city_slug: result.location.city_slug,
          source: result.source
        }
      end
    end
  end
end
