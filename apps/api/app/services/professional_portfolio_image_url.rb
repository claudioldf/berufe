# frozen_string_literal: true

class ProfessionalPortfolioImageUrl
  def self.call(item, environment: ENV)
    PublicMediaUrl.call(
      rails_path: "/api/v1/professional/portfolio-items/#{item.id}/image",
      environment:
    )
  end
end
