# frozen_string_literal: true

module Api
  module V1
    module Admin
      class CatalogsController < CatalogBaseController
        def show
          render_catalog(catalog_management.snapshot)
        end
      end
    end
  end
end
