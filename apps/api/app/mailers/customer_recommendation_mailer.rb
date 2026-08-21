# frozen_string_literal: true

class CustomerRecommendationMailer < ApplicationMailer
  def invitation
    request_record = params.fetch(:request_record)
    token = params.fetch(:token)
    quote = request_record.service_job.quote
    professional = quote.professional
    revision = professional.published_revision || professional.working_revision

    @customer_name = quote.customer_name
    @professional_name = revision.display_name
    @service_description = quote.service_description
    @recommendation_url = "#{ENV.fetch("WEB_ORIGIN").delete_suffix("/")}/recomendacao/#{token}"

    mail(
      to: quote.customer_email,
      subject: "Como foi o serviço de #{@professional_name}?"
    )
  end
end
