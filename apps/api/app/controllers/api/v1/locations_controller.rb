# frozen_string_literal: true

module Api
  module V1
    class LocationsController < BaseController
      def states
        render_locations(State.ordered.map { |state| LocationSerializer.state(state) })
      rescue ActiveRecord::ActiveRecordError => error
        render_location_unavailable(error)
      end

      def cities
        state = State.find_by!(abbreviation: params[:state_abbreviation].to_s.upcase)
        render_locations(state.cities.ordered.includes(:state).map { |city| LocationSerializer.city(city) })
      rescue ActiveRecord::RecordNotFound
        raise
      rescue ActiveRecord::ActiveRecordError => error
        render_location_unavailable(error)
      end

      def neighborhoods
        city = City.find(params[:city_code])
        render_locations(city.neighborhoods.ordered.map { |neighborhood| LocationSerializer.neighborhood(neighborhood) })
      rescue ActiveRecord::RecordNotFound
        raise
      rescue ActiveRecord::ActiveRecordError => error
        render_location_unavailable(error)
      end

      private

      def render_locations(data)
        render json: {data:, request_id: Current.request_id}
      end

      def render_location_unavailable(error)
        report_service_error(error)
        render_api_error(
          code: "service_unavailable",
          message: "Localidades temporariamente indisponíveis.",
          status: :service_unavailable
        )
      end
    end
  end
end
