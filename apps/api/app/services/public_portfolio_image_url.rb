# frozen_string_literal: true

class PublicPortfolioImageUrl
  def self.call(item, environment: ENV)
    base_url = environment.fetch("API_PUBLIC_URL").delete_suffix("/")
    "#{base_url}/api/v1/public/portfolio-items/#{item.id}/image"
  end
end
