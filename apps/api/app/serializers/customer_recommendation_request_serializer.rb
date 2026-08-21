# frozen_string_literal: true

class CustomerRecommendationRequestSerializer
  def initialize(request)
    @request = request
  end

  def as_json(*)
    quote = request.service_job.quote
    professional = quote.professional
    revision = professional.published_revision || professional.working_revision
    {
      customer_name: quote.customer_name,
      service_description: quote.service_description,
      professional: {
        display_name: revision.display_name,
        public_slug: professional.public_slug
      },
      expires_at: request.expires_at.iso8601
    }
  end

  private

  attr_reader :request
end
