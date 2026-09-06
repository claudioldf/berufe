# frozen_string_literal: true

class PublicPortfolioImageUrl
  def self.call(item, environment: ENV)
    PublicMediaUrl.call(
      rails_path: "/api/v1/public/portfolio-items/#{item.id}/image",
      host: :media,
      environment:
    )
  end
end
