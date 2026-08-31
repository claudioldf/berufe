# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Quote service loop", type: :request, openapi: true do
  let(:account) do
    UserAccount.create!(phone_e164: "+5547999997611", role: "professional", status: "active")
  end
  let(:profile) { ProfessionalProfile.create!(user_account: account, display_name: "Ana Souza") }
  let(:session_token) do
    profile
    ApplicationSession.issue!(user_account: account).last
  end
  let(:quote) do
    ProfessionalQuoteWriter.new.call(
      profile:,
      attributes: {
        customer: {
          id: nil,
          name: "Marina Cliente",
          whatsapp_e164: "+5547999912611",
          email: "marina@example.com"
        },
        service_description: "Instalação de luminárias",
        service_address: "Rua das Flores, 100",
        scheduled_on: Date.current + 3.days,
        discount_amount: 0,
        valid_until: Date.current + 7.days,
        notes: nil,
        items: [
          {description: "Instalação", quantity: 2, unit: "ponto", unit_price: 120}
        ]
      }
    )
  end

  before { make_profile_publicly_eligible(profile) }

  it "keeps one owner-scoped customer and closes approval, service, email, and recommendation" do
    share = ProfessionalQuoteSharer.new.call(quote:, method: "copy")
    token = URI(share.share_url).path.split("/").last
    original_token_hash = quote.reload.share_token_hash

    post "/api/v1/shared-quotes/decisions",
      params: {
        token:,
        decision: {
          kind: "request_change",
          revision: quote.lock_version,
          terms_accepted: false,
          message: "Trocar uma luminária de lugar."
        }
      },
      headers: public_headers("quote-change-request"),
      as: :json
    expect(response).to have_http_status(:ok)
    expect(quote.reload).to have_attributes(
      status: "change_requested",
      customer_decision_message: "Trocar uma luminária de lugar."
    )
    expect(quote.quote_change_requests.sole).to have_attributes(
      message: "Trocar uma luminária de lugar."
    )
    expect(quote.service_job).to be_nil
    expect(Notification.find_by!(notification_type: "quote_change_requested")).to have_attributes(
      recipient_user_account: account,
      route_params: {"quote_id" => quote.id}
    )
    assert_api_conform(status: 200)

    old_revision = quote.lock_version
    ProfessionalQuoteWriter.new.call(
      profile:,
      quote:,
      attributes: {
        revision: quote.lock_version,
        customer: {
          id: quote.customer_id,
          name: quote.customer_name,
          whatsapp_e164: quote.customer_phone_e164,
          email: quote.customer_email
        },
        service_description: "Instalação revisada de luminárias",
        service_address: quote.service_address,
        scheduled_on: quote.scheduled_on,
        discount_amount: 0,
        valid_until: quote.valid_until,
        notes: nil,
        items: [
          {description: "Instalação", quantity: 2, unit: "ponto", unit_price: 120}
        ]
      }
    )
    reshared = ProfessionalQuoteSharer.new.call(quote: quote.reload, method: "copy")
    expect(URI(reshared.share_url).path.split("/").last).to eq(token)
    expect(quote.reload).to have_attributes(
      status: "shared",
      share_token_hash: original_token_hash,
      customer_decision_message: nil
    )
    expect(quote.quote_change_requests.sole.message).to eq("Trocar uma luminária de lugar.")

    get "/api/v1/professional/quotes/#{quote.id}",
      headers: session_read_headers("quote-change-history")
    expect(response).to have_http_status(:ok)
    expect(response.parsed_body.dig("data", "quote", "change_requests").sole).to include(
      "message" => "Trocar uma luminária de lugar."
    )
    assert_api_conform(status: 200)

    post "/api/v1/shared-quotes/decisions",
      params: {
        token:,
        decision: {
          kind: "approve",
          revision: old_revision,
          terms_accepted: true,
          message: nil
        }
      },
      headers: public_headers("quote-stale-approval"),
      as: :json
    expect(response).to have_http_status(:conflict)
    expect(response.parsed_body.dig("error", "code")).to eq("quote_stale")
    assert_api_conform(status: 409)

    post "/api/v1/shared-quotes/decisions",
      params: {
        token:,
        decision: {
          kind: "approve",
          revision: quote.reload.lock_version,
          terms_accepted: true,
          message: nil
        }
      },
      headers: public_headers("quote-approval"),
      as: :json
    expect(response).to have_http_status(:ok)
    expect(quote.reload).to be_approved
    expect(quote.terms_accepted_at).to be_present
    service_job = quote.service_job
    expect(service_job).to be_approved
    expect(ServiceJob.where(quote:).count).to eq(1)
    expect(Notification.find_by!(notification_type: "quote_approved")).to have_attributes(
      recipient_user_account: account,
      route_params: {"quote_id" => quote.id}
    )
    assert_api_conform(status: 200)

    get "/api/v1/professional/service-jobs",
      headers: session_read_headers("service-job-list")
    expect(response).to have_http_status(:ok)
    expect(response.parsed_body.dig("data", "service_jobs").sole.fetch("id")).to eq(service_job.id)
    assert_api_conform(status: 200)

    get "/api/v1/professional/service-jobs/#{service_job.id}",
      headers: session_read_headers("service-job-show")
    expect(response).to have_http_status(:ok)
    expect(response.parsed_body.dig("data", "service_job", "id")).to eq(service_job.id)
    assert_api_conform(status: 200)

    post "/api/v1/shared-quotes/decisions",
      params: {
        token:,
        decision: {
          kind: "approve",
          revision: quote.lock_version,
          terms_accepted: true,
          message: nil
        }
      },
      headers: public_headers("quote-approval-retry"),
      as: :json
    expect(response).to have_http_status(:ok)
    expect(ServiceJob.where(quote:).count).to eq(1)

    patch "/api/v1/professional/quotes/#{quote.id}",
      params: {
        quote: {
          revision: quote.lock_version,
          customer: {
            id: quote.customer_id,
            name: "Nome alterado",
            whatsapp_e164: quote.customer_phone_e164,
            email: quote.customer_email
          },
          service_description: quote.service_description,
          service_address: quote.service_address,
          scheduled_on: quote.scheduled_on,
          discount_amount: 0,
          valid_until: quote.valid_until,
          notes: nil,
          items: [{description: "Instalação", quantity: 2, unit: "ponto", unit_price: 120}]
        }
      },
      headers: session_headers("approved-quote-update"),
      as: :json
    expect(response).to have_http_status(:conflict)
    expect(quote.reload.customer_name).to eq("Marina Cliente")
    assert_api_conform(status: 409)

    completion_item = ProfessionalActionInboxQuery.new.call(profile:).find do |item|
      item.id == service_job.id && item.kind == "service_open"
    end
    expect(completion_item.recommendation_delivery_channel).to eq("email")

    # The professional closes the job themselves — there is no customer-
    # confirmation round trip. Their explicit evaluation choice creates and
    # immediately enqueues the email request after completion commits.
    expect do
      post "/api/v1/professional/service-jobs/#{service_job.id}/complete",
        params: {completion: {request_recommendation: true}},
        headers: session_headers("service-complete"),
        as: :json
    end.to have_enqueued_job(CustomerRecommendationRequestDeliveryJob).at(:no_wait)
    expect(response).to have_http_status(:ok)
    expect(response.parsed_body.dig("data", "service_job")).to include("status" => "completed")
    expect(service_job.reload).to have_attributes(status: "completed")
    expect(service_job.completed_at).to be_present
    assert_api_conform(status: 200)

    recommendation_request = service_job.customer_recommendation_request
    expect(recommendation_request).to have_attributes(
      status: "open",
      delivery_channel: "email",
      sent_at: nil
    )
    recommendation_token = CustomerRecommendationToken.decrypt(
      recommendation_request.token_ciphertext
    )
    expect(recommendation_token).to start_with("br_")

    post "/api/v1/customer-recommendations/resolve",
      params: {token: recommendation_token},
      headers: public_headers("recommendation-before-delivery"),
      as: :json
    expect(response).to have_http_status(:not_found)
    assert_api_conform(status: 404)

    ActionMailer::Base.deliveries.clear
    CustomerRecommendationRequestDeliveryJob.perform_now(recommendation_request.id)
    expect(ActionMailer::Base.deliveries.one?).to be(true)
    delivered_email = ActionMailer::Base.deliveries.first
    expect(delivered_email.to).to eq(["marina@example.com"])
    expect(delivered_email.subject).to eq("Como foi o serviço de #{profile.display_name}?")
    expect(delivered_email).to be_multipart
    expect(delivered_email.text_part.body.decoded).to include(
      "Como foi o serviço?",
      "Instalação revisada de luminárias",
      "avisar #{profile.display_name} em particular",
      recommendation_token
    )
    expect(delivered_email.text_part.body.decoded).not_to include("Você confirmou a conclusão")
    expect(delivered_email.html_part.body.decoded).to include(
      "berufe<span style=\"color: #f8755d;\">.</span>",
      "Como foi o serviço?",
      "Contar como foi",
      "background-color: #12625d",
      recommendation_token
    )
    expect(delivered_email.html_part.body.decoded).not_to include("Você confirmou a conclusão")
    expect(recommendation_request.reload).to have_attributes(
      token_ciphertext: nil
    )
    expect(recommendation_request.sent_at).to be_present
    CustomerRecommendationRequestDeliveryJob.perform_now(recommendation_request.id)
    expect(ActionMailer::Base.deliveries.one?).to be(true)

    post "/api/v1/customer-recommendations/resolve",
      params: {token: recommendation_token},
      headers: public_headers("recommendation-resolve"),
      as: :json
    expect(response).to have_http_status(:ok)
    expect(response.parsed_body.dig("data", "recommendation_request")).to include(
      "customer_name" => "Marina Cliente",
      "service_description" => "Instalação revisada de luminárias"
    )
    assert_api_conform(status: 200)

    post "/api/v1/customer-recommendations",
      params: {
        token: recommendation_token,
        recommendation: {
          display_name: "Marina",
          recommendation_text: "Trabalho cuidadoso e comunicação muito clara.",
          service_confirmed: true,
          publication_consent: true
        }
      },
      headers: public_headers("recommendation-create"),
      as: :json
    expect(response).to have_http_status(:created)
    expect(recommendation_request.reload).to be_completed
    expect(quote.customer.reload.email_verified_at).to be_present
    expect(CustomerRecommendation.sole).to have_attributes(
      display_name: "Marina",
      privacy_notice_version: LegalDocumentVersions::PRIVACY_NOTICE
    )
    expect(Notification.find_by!(notification_type: "customer_recommendation_published")).to have_attributes(
      recipient_user_account: account,
      route_params: {}
    )
    assert_api_conform(status: 201)

    get "/api/v1/public/professionals/#{profile.public_slug}",
      headers: {"X-Request-Id" => "recommendation-public-profile"}
    expect(response).to have_http_status(:ok)
    professional = response.parsed_body.dig("data", "professional")
    expect(professional.fetch("evidence_summary")).to include(
      "registered_services" => 1,
      "recommendations" => 1,
      "hidden_recommendations" => 0
    )
    expect(professional.fetch("customer_recommendations").sole).to include(
      "display_name" => "Marina",
      "verification_label" => "Link enviado por e-mail"
    )
    assert_api_conform(status: 200)

    # Self-serve hiding (S069): unmoderated, but the public profile discloses
    # the count so a reader can always tell hiding occurred.
    get "/api/v1/professional/recommendations",
      headers: {"X-Request-Id" => "recommendations-list-anonymous"}
    expect(response).to have_http_status(:unauthorized)
    assert_api_conform(status: 401)

    get "/api/v1/professional/recommendations",
      headers: session_read_headers("recommendations-list")
    expect(response).to have_http_status(:ok)
    listed_recommendation = response.parsed_body.dig("data", "recommendations").sole
    expect(listed_recommendation).to include("display_name" => "Marina", "hidden_at" => nil)
    assert_api_conform(status: 200)

    post "/api/v1/professional/recommendations/#{listed_recommendation.fetch("id")}/hide",
      params: {hide: {reason: nil}},
      headers: {"Origin" => ENV.fetch("WEB_ORIGIN"), "X-Request-Id" => "recommendation-hide-anonymous"},
      as: :json
    expect(response).to have_http_status(:unauthorized)
    assert_api_conform(status: 401)

    post "/api/v1/professional/recommendations/#{listed_recommendation.fetch("id")}/hide",
      params: {hide: {reason: nil}},
      headers: session_headers("recommendation-hide-bad-origin").merge("Origin" => "https://untrusted.example"),
      as: :json
    expect(response).to have_http_status(:forbidden)
    assert_api_conform(status: 403)

    post "/api/v1/professional/recommendations/#{SecureRandom.uuid}/hide",
      params: {hide: {reason: nil}},
      headers: session_headers("recommendation-hide-missing"),
      as: :json
    expect(response).to have_http_status(:not_found)
    assert_api_conform(status: 404)

    post "/api/v1/professional/recommendations/#{listed_recommendation.fetch("id")}/hide",
      params: {hide: {reason: "Cliente pediu para não publicar."}},
      headers: session_headers("recommendation-hide"),
      as: :json
    expect(response).to have_http_status(:ok)
    expect(response.parsed_body.dig("data", "recommendation", "hidden_at")).to be_present
    assert_api_conform(status: 200)

    get "/api/v1/public/professionals/#{profile.public_slug}",
      headers: {"X-Request-Id" => "recommendation-hidden-public-profile"}
    expect(response).to have_http_status(:ok)
    expect(response.parsed_body.dig("data", "professional", "customer_recommendations")).to be_empty
    expect(response.parsed_body.dig("data", "professional", "evidence_summary")).to include(
      "recommendations" => 0,
      "hidden_recommendations" => 1
    )
    assert_api_conform(status: 200)

    post "/api/v1/professional/recommendations/#{listed_recommendation.fetch("id")}/unhide",
      headers: {"Origin" => ENV.fetch("WEB_ORIGIN"), "X-Request-Id" => "recommendation-unhide-anonymous"},
      as: :json
    expect(response).to have_http_status(:unauthorized)
    assert_api_conform(status: 401)

    post "/api/v1/professional/recommendations/#{listed_recommendation.fetch("id")}/unhide",
      headers: session_headers("recommendation-unhide-bad-origin").merge("Origin" => "https://untrusted.example"),
      as: :json
    expect(response).to have_http_status(:forbidden)
    assert_api_conform(status: 403)

    post "/api/v1/professional/recommendations/#{SecureRandom.uuid}/unhide",
      headers: session_headers("recommendation-unhide-missing"),
      as: :json
    expect(response).to have_http_status(:not_found)
    assert_api_conform(status: 404)

    post "/api/v1/professional/recommendations/#{listed_recommendation.fetch("id")}/unhide",
      headers: session_headers("recommendation-unhide"),
      as: :json
    expect(response).to have_http_status(:ok)
    expect(response.parsed_body.dig("data", "recommendation", "hidden_at")).to be_nil
    assert_api_conform(status: 200)

    CustomerRecommendationPublicationWithdrawer.new.call(
      profile_slug: profile.public_slug,
      email: "marina@example.com"
    )
    get "/api/v1/public/professionals/#{profile.public_slug}",
      headers: {"X-Request-Id" => "recommendation-withdrawn-public-profile"}
    expect(response).to have_http_status(:ok)
    expect(response.parsed_body.dig("data", "professional", "customer_recommendations")).to be_empty
    expect(response.parsed_body.dig("data", "professional", "evidence_summary", "recommendations")).to eq(0)
    assert_api_conform(status: 200)
  end

  it "lets the professional complete a service without requesting an evaluation" do
    share = ProfessionalQuoteSharer.new.call(quote:, method: "copy")
    token = URI(share.share_url).path.split("/").last
    service_job = SharedQuoteDecisionRecorder.new.call(
      token:,
      decision: "approve",
      revision: quote.reload.lock_version,
      terms_accepted: true,
      message: nil
    )[:service_job]

    expect do
      post "/api/v1/professional/service-jobs/#{service_job.id}/complete",
        params: {completion: {request_recommendation: false}},
        headers: session_headers("service-complete"),
        as: :json
    end.not_to have_enqueued_job(CustomerRecommendationRequestDeliveryJob)

    expect(response).to have_http_status(:ok)
    expect(response.parsed_body.dig("data", "service_job")).to include("status" => "completed")
    expect(response.parsed_body.dig("data", "service_job")).not_to have_key("completion_confirmed_by")
    expect(service_job.reload).to have_attributes(status: "completed")
    expect(service_job.completed_at).to be_present
    expect(service_job.customer_recommendation_request).to be_nil
    expect(response.parsed_body.dig("data", "service_job", "recommendation")).to be_nil
    expect(response.parsed_body.dig("data", "share_url")).to be_nil
    expect(response.parsed_body.dig("data", "whatsapp_url")).to be_nil
    assert_api_conform(status: 200)

    post "/api/v1/professional/service-jobs/#{service_job.id}/complete",
      params: {completion: {request_recommendation: true}},
      headers: session_headers("service-complete-again"),
      as: :json
    expect(response).to have_http_status(:conflict)
    assert_api_conform(status: 409)
  end

  it "searches only the current professional's customers" do
    owned = profile.customers.create!(
      name: "Marina Cliente",
      whatsapp_e164: "+5547999912612",
      email: "marina@example.com"
    )
    other_account = UserAccount.create!(
      phone_e164: "+5547999997612",
      role: "professional",
      status: "active"
    )
    other_profile = ProfessionalProfile.create!(
      user_account: other_account,
      display_name: "Outro Profissional"
    )
    other_profile.customers.create!(
      name: "Marina de outro profissional",
      whatsapp_e164: "+5547999912613",
      email: "outra@example.com"
    )

    get "/api/v1/professional/customer-candidates",
      params: {query: "Marina"},
      headers: {
        "X-Request-Id" => "customer-candidates",
        "Cookie" => "#{ApplicationSession::COOKIE_NAME}=#{session_token}"
      }
    expect(response).to have_http_status(:ok)
    expect(response.parsed_body.dig("data", "customers")).to contain_exactly(
      include(
        "id" => owned.id,
        "name" => "Marina Cliente",
        "whatsapp_e164" => "+5547999912612"
      )
    )
    assert_api_conform(status: 200)

    get "/api/v1/professional/customer-candidates",
      params: {query: "Marina"},
      headers: {"X-Request-Id" => "customer-candidates-anonymous"}
    expect(response).to have_http_status(:unauthorized)
    assert_api_conform(status: 401)

    get "/api/v1/professional/customer-candidates",
      params: {query: "M" * 81},
      headers: session_read_headers("customer-candidates-invalid")
    expect(response).to have_http_status(:unprocessable_entity)
    assert_api_conform(status: 422)
  end

  it "returns safe errors for lifecycle endpoints and supports service cancellation" do
    share = ProfessionalQuoteSharer.new.call(quote:, method: "copy")
    token = URI(share.share_url).path.split("/").last

    post "/api/v1/shared-quotes/decisions",
      params: {
        token:,
        decision: {
          kind: "approve",
          revision: quote.reload.lock_version,
          terms_accepted: false,
          message: nil
        }
      },
      headers: public_headers("quote-decision-invalid"),
      as: :json
    expect(response).to have_http_status(:unprocessable_entity)
    assert_api_conform(status: 422)

    post "/api/v1/shared-quotes/decisions",
      params: {
        token:,
        decision: {
          kind: "approve",
          revision: quote.lock_version,
          terms_accepted: true,
          message: nil
        }
      },
      headers: {"Origin" => "https://untrusted.example", "X-Request-Id" => "decision-origin"},
      as: :json
    expect(response).to have_http_status(:forbidden)
    assert_api_conform(status: 403)

    post "/api/v1/shared-quotes/decisions",
      params: {
        token: "invalid",
        decision: {kind: "decline", revision: 0, terms_accepted: false, message: nil}
      },
      headers: public_headers("decision-missing"),
      as: :json
    expect(response).to have_http_status(:not_found)
    assert_api_conform(status: 404)

    expired_quote = ProfessionalQuoteWriter.new.call(
      profile:,
      attributes: {
        customer: {
          id: nil,
          name: "Cliente Expirado",
          whatsapp_e164: "+5547999912614",
          email: nil
        },
        service_description: "Serviço expirado",
        discount_amount: 0,
        valid_until: Time.current
          .in_time_zone(ProfessionalDailyActivity::PRODUCT_TIME_ZONE)
          .to_date - 1.day,
        items: [{description: "Item", quantity: 1, unit: "serviço", unit_price: 10}]
      }
    )
    expired_share = ProfessionalQuoteSharer.new.call(quote: expired_quote, method: "copy")
    expired_token = URI(expired_share.share_url).path.split("/").last
    post "/api/v1/shared-quotes/decisions",
      params: {
        token: expired_token,
        decision: {
          kind: "approve",
          revision: expired_quote.reload.lock_version,
          terms_accepted: true,
          message: nil
        }
      },
      headers: public_headers("decision-expired"),
      as: :json
    expect(response).to have_http_status(:gone)
    expect(response.parsed_body.dig("error", "message")).to eq(
      "Este orçamento venceu e não pode mais ser aprovado. " \
      "Fale com o profissional para solicitar uma nova versão."
    )
    assert_api_conform(status: 410)

    approved = SharedQuoteDecisionRecorder.new.call(
      token:,
      decision: "approve",
      revision: quote.reload.lock_version,
      terms_accepted: true,
      message: nil
    )
    service_job = approved[:service_job]

    get "/api/v1/professional/service-jobs",
      headers: {"X-Request-Id" => "service-job-list-anonymous"}
    expect(response).to have_http_status(:unauthorized)
    assert_api_conform(status: 401)

    get "/api/v1/professional/service-jobs/#{service_job.id}",
      headers: {"X-Request-Id" => "service-job-show-anonymous"}
    expect(response).to have_http_status(:unauthorized)
    assert_api_conform(status: 401)

    get "/api/v1/professional/service-jobs/#{SecureRandom.uuid}",
      headers: session_read_headers("service-job-show-missing")
    expect(response).to have_http_status(:not_found)
    assert_api_conform(status: 404)

    post "/api/v1/professional/service-jobs/#{service_job.id}/recommendation-request",
      headers: {"Origin" => ENV.fetch("WEB_ORIGIN"), "X-Request-Id" => "recommendation-request-anonymous"},
      as: :json
    expect(response).to have_http_status(:unauthorized)
    assert_api_conform(status: 401)

    post "/api/v1/professional/service-jobs/#{service_job.id}/recommendation-request",
      headers: session_headers("recommendation-request-bad-origin").merge("Origin" => "https://untrusted.example"),
      as: :json
    expect(response).to have_http_status(:forbidden)
    assert_api_conform(status: 403)

    post "/api/v1/professional/service-jobs/#{SecureRandom.uuid}/recommendation-request",
      headers: session_headers("recommendation-request-missing"),
      as: :json
    expect(response).to have_http_status(:not_found)
    assert_api_conform(status: 404)

    # Not completed yet, so the WhatsApp handoff has nothing to reuse.
    post "/api/v1/professional/service-jobs/#{service_job.id}/recommendation-request",
      headers: session_headers("recommendation-request-not-completed"),
      as: :json
    expect(response).to have_http_status(:conflict)
    assert_api_conform(status: 409)

    post "/api/v1/professional/service-jobs/#{service_job.id}/complete",
      params: {completion: {request_recommendation: true}},
      headers: {
        "Origin" => ENV.fetch("WEB_ORIGIN"),
        "X-Request-Id" => "service-complete-anonymous"
      },
      as: :json
    expect(response).to have_http_status(:unauthorized)
    assert_api_conform(status: 401)

    post "/api/v1/professional/service-jobs/#{service_job.id}/complete",
      params: {completion: {request_recommendation: true}},
      headers: session_headers("service-complete-bad-origin").merge(
        "Origin" => "https://untrusted.example"
      ),
      as: :json
    expect(response).to have_http_status(:forbidden)
    assert_api_conform(status: 403)

    post "/api/v1/professional/service-jobs/#{SecureRandom.uuid}/complete",
      params: {completion: {request_recommendation: true}},
      headers: session_headers("service-complete-missing"),
      as: :json
    expect(response).to have_http_status(:not_found)
    assert_api_conform(status: 404)

    post "/api/v1/professional/service-jobs/#{service_job.id}/complete",
      params: {completion: {}},
      headers: session_headers("service-complete-missing-choice"),
      as: :json
    expect(response).to have_http_status(:unprocessable_entity)
    expect(response.parsed_body.dig("error", "field_errors")).to include(
      "completion" => ["é obrigatório"]
    )

    post "/api/v1/professional/service-jobs/#{service_job.id}/complete",
      params: {completion: {request_recommendation: "yes"}},
      headers: session_headers("service-complete-invalid-choice"),
      as: :json
    expect(response).to have_http_status(:unprocessable_entity)
    expect(response.parsed_body.dig("error", "field_errors")).to include(
      "request_recommendation" => ["deve ser verdadeiro ou falso"]
    )

    post "/api/v1/professional/service-jobs/#{service_job.id}/cancel",
      params: {cancellation: {reason: "Cliente adiou o serviço."}},
      headers: session_headers("service-cancel"),
      as: :json
    expect(response).to have_http_status(:ok)
    expect(service_job.reload).to be_cancelled
    assert_api_conform(status: 200)

    post "/api/v1/professional/service-jobs/#{service_job.id}/cancel",
      params: {cancellation: {reason: nil}},
      headers: {"Origin" => ENV.fetch("WEB_ORIGIN"), "X-Request-Id" => "service-cancel-anonymous"},
      as: :json
    expect(response).to have_http_status(:unauthorized)
    assert_api_conform(status: 401)

    post "/api/v1/professional/service-jobs/#{service_job.id}/cancel",
      params: {cancellation: {reason: nil}},
      headers: session_headers("service-cancel-origin").merge("Origin" => "https://untrusted.example"),
      as: :json
    expect(response).to have_http_status(:forbidden)
    assert_api_conform(status: 403)

    post "/api/v1/professional/service-jobs/#{SecureRandom.uuid}/cancel",
      params: {cancellation: {reason: nil}},
      headers: session_headers("service-cancel-missing"),
      as: :json
    expect(response).to have_http_status(:not_found)
    assert_api_conform(status: 404)

    post "/api/v1/professional/service-jobs/#{service_job.id}/cancel",
      params: {cancellation: {reason: nil}},
      headers: session_headers("service-cancel-unavailable"),
      as: :json
    expect(response).to have_http_status(:conflict)
    assert_api_conform(status: 409)

    another_quote = ProfessionalQuoteWriter.new.call(
      profile:,
      attributes: {
        customer: {
          id: nil,
          name: "Outro Cliente",
          whatsapp_e164: "+5547999912615",
          email: nil
        },
        service_description: "Outro serviço",
        valid_until: Date.current + 30.days,
        discount_amount: 0,
        items: [{description: "Item", quantity: 1, unit: "serviço", unit_price: 10}]
      }
    )
    another_share = ProfessionalQuoteSharer.new.call(quote: another_quote, method: "copy")
    another_token = URI(another_share.share_url).path.split("/").last
    another_job = SharedQuoteDecisionRecorder.new.call(
      token: another_token,
      decision: "approve",
      revision: another_quote.reload.lock_version,
      terms_accepted: true,
      message: nil
    )[:service_job]
    post "/api/v1/professional/service-jobs/#{another_job.id}/cancel",
      params: {cancellation: {reason: "x" * 701}},
      headers: session_headers("service-cancel-invalid"),
      as: :json
    expect(response).to have_http_status(:unprocessable_entity)
    assert_api_conform(status: 422)
  end

  it "uses generic recommendation bearer errors and preserves a newer customer email" do
    share = ProfessionalQuoteSharer.new.call(quote:, method: "copy")
    token = URI(share.share_url).path.split("/").last
    service_job = SharedQuoteDecisionRecorder.new.call(
      token:,
      decision: "approve",
      revision: quote.reload.lock_version,
      terms_accepted: true,
      message: nil
    )[:service_job]
    service_job.update!(status: "completed", completed_at: Time.current)
    recommendation_token = CustomerRecommendationToken.issue
    request_record = service_job.create_customer_recommendation_request!(
      token_hash: CustomerRecommendationToken.digest(recommendation_token),
      token_ciphertext: CustomerRecommendationToken.encrypt(recommendation_token),
      delivery_channel: "email",
      email_fingerprint: CustomerEmailFingerprint.call(quote.customer_email),
      expires_at: 14.days.from_now,
      sent_at: Time.current
    )

    post "/api/v1/customer-recommendations/resolve",
      params: {token: recommendation_token},
      headers: {"Origin" => "https://untrusted.example", "X-Request-Id" => "recommendation-origin"},
      as: :json
    expect(response).to have_http_status(:forbidden)
    assert_api_conform(status: 403)

    post "/api/v1/customer-recommendations/resolve",
      params: {token: "invalid"},
      headers: public_headers("recommendation-missing"),
      as: :json
    expect(response).to have_http_status(:not_found)
    assert_api_conform(status: 404)

    post "/api/v1/customer-recommendations",
      params: {
        token: recommendation_token,
        recommendation: {
          display_name: "Marina",
          recommendation_text: "Ótimo serviço.",
          service_confirmed: true,
          publication_consent: true
        }
      },
      headers: {"Origin" => "https://untrusted.example", "X-Request-Id" => "recommendation-create-origin"},
      as: :json
    expect(response).to have_http_status(:forbidden)
    assert_api_conform(status: 403)

    post "/api/v1/customer-recommendations",
      params: {
        token: "invalid",
        recommendation: {
          display_name: "Marina",
          recommendation_text: "Ótimo serviço.",
          service_confirmed: true,
          publication_consent: true
        }
      },
      headers: public_headers("recommendation-create-missing"),
      as: :json
    expect(response).to have_http_status(:not_found)
    assert_api_conform(status: 404)

    post "/api/v1/customer-recommendations",
      params: {
        token: recommendation_token,
        recommendation: {
          display_name: "Marina",
          recommendation_text: "Ótimo serviço.",
          service_confirmed: false,
          publication_consent: false
        }
      },
      headers: public_headers("recommendation-create-invalid"),
      as: :json
    expect(response).to have_http_status(:unprocessable_entity)
    assert_api_conform(status: 422)

    quote.customer.update!(email: "novo-email@example.com")
    post "/api/v1/customer-recommendations",
      params: {
        token: recommendation_token,
        recommendation: {
          display_name: "Marina",
          recommendation_text: "Ótimo serviço e atendimento cuidadoso.",
          service_confirmed: true,
          publication_consent: true
        }
      },
      headers: public_headers("recommendation-create-after-email-change"),
      as: :json
    expect(response).to have_http_status(:created)
    expect(request_record.reload).to be_completed
    expect(quote.customer.reload.email).to eq("novo-email@example.com")
    expect(quote.customer.email_verified_at).to be_nil
    assert_api_conform(status: 201)
  end

  it "asks for a recommendation over WhatsApp when the quote has no customer email" do
    whatsapp_quote = ProfessionalQuoteWriter.new.call(
      profile:,
      attributes: {
        customer: {id: nil, name: "Cliente Whatsapp", whatsapp_e164: "+5547999912699", email: nil},
        service_description: "Reparo hidráulico",
        discount_amount: 0,
        valid_until: Date.current + 7.days,
        items: [{description: "Reparo", quantity: 1, unit: "serviço", unit_price: 200}]
      }
    )
    whatsapp_share = ProfessionalQuoteSharer.new.call(quote: whatsapp_quote, method: "copy")
    whatsapp_token = URI(whatsapp_share.share_url).path.split("/").last
    service_job = SharedQuoteDecisionRecorder.new.call(
      token: whatsapp_token,
      decision: "approve",
      revision: whatsapp_quote.reload.lock_version,
      terms_accepted: true,
      message: nil
    )[:service_job]

    completion_item = ProfessionalActionInboxQuery.new.call(profile:).find do |item|
      item.id == service_job.id && item.kind == "service_open"
    end
    expect(completion_item.recommendation_delivery_channel).to eq("whatsapp")

    expect do
      post "/api/v1/professional/service-jobs/#{service_job.id}/complete",
        params: {completion: {request_recommendation: true}},
        headers: session_headers("whatsapp-complete"),
        as: :json
    end.not_to have_enqueued_job(CustomerRecommendationRequestDeliveryJob)
    expect(response).to have_http_status(:ok)
    request_record = service_job.reload.customer_recommendation_request
    expect(request_record).to have_attributes(
      delivery_channel: "whatsapp",
      email_fingerprint: nil,
      sent_at: be_present
    )
    first_share_url = response.parsed_body.dig("data", "share_url")
    expect(response.parsed_body.dig("data", "whatsapp_url")).to start_with(
      "https://wa.me/5547999912699?"
    )
    handoff_message = URI.decode_www_form(
      URI(response.parsed_body.dig("data", "whatsapp_url")).query
    ).to_h.fetch("text")
    expect(handoff_message).to eq(
      "Olá, Cliente Whatsapp! Poderia contar como foi o serviço reparo hidráulico? #{first_share_url}"
    )
    assert_api_conform(status: 200)

    # Reusable: a second tap reopens the same link rather than invalidating it,
    # unlike the one-shot email channel.
    post "/api/v1/professional/service-jobs/#{service_job.id}/recommendation-request",
      headers: session_headers("whatsapp-handoff"),
      as: :json
    expect(response).to have_http_status(:ok)
    expect(response.parsed_body.dig("data", "share_url")).to eq(first_share_url)
    expect(request_record.reload.sent_at).to be_present
    assert_api_conform(status: 200)

    post "/api/v1/professional/service-jobs/#{service_job.id}/recommendation-request",
      headers: session_headers("whatsapp-handoff-again"),
      as: :json
    expect(response).to have_http_status(:ok)
    expect(response.parsed_body.dig("data", "share_url")).to eq(first_share_url)

    recommendation_token = first_share_url.split("/").last
    post "/api/v1/customer-recommendations",
      params: {
        token: recommendation_token,
        recommendation: {
          display_name: "Cliente Whatsapp",
          recommendation_text: "Serviço rápido e bem explicado.",
          service_confirmed: true,
          publication_consent: true
        }
      },
      headers: public_headers("whatsapp-recommendation-create"),
      as: :json
    expect(response).to have_http_status(:created)
    published = CustomerRecommendation.sole
    expect(published).to have_attributes(
      delivery_channel: "whatsapp",
      email_fingerprint: nil,
      email_verified_at: nil
    )
    assert_api_conform(status: 201)

    get "/api/v1/public/professionals/#{profile.public_slug}",
      headers: {"X-Request-Id" => "whatsapp-recommendation-public-profile"}
    expect(response.parsed_body.dig("data", "professional", "customer_recommendations").sole).to include(
      "verification_label" => "Link enviado por WhatsApp"
    )
    assert_api_conform(status: 200)
  end

  it "lets a customer privately report an outstanding issue instead of recommending" do
    share = ProfessionalQuoteSharer.new.call(quote:, method: "copy")
    token = URI(share.share_url).path.split("/").last
    service_job = SharedQuoteDecisionRecorder.new.call(
      token:,
      decision: "approve",
      revision: quote.reload.lock_version,
      terms_accepted: true,
      message: nil
    )[:service_job]
    post "/api/v1/professional/service-jobs/#{service_job.id}/complete",
      params: {completion: {request_recommendation: true}},
      headers: session_headers("issue-complete"),
      as: :json
    expect(response).to have_http_status(:ok)
    request_record = service_job.reload.customer_recommendation_request
    recommendation_token = CustomerRecommendationToken.decrypt(request_record.token_ciphertext)
    # Simulate the asynchronous email worker completing delivery.
    request_record.update!(sent_at: Time.current)

    post "/api/v1/customer-recommendations/issues",
      params: {token: recommendation_token, message: "Faltou revisar o encaixe da luminária."},
      headers: public_headers("feedback-issue"),
      as: :json
    expect(response).to have_http_status(:ok)
    expect(response.parsed_body.dig("data", "recommendation_request")).to include(
      "customer_name" => "Marina Cliente"
    )
    assert_api_conform(status: 200)

    expect(service_job.reload).to have_attributes(
      status: "completed",
      customer_feedback_message: "Faltou revisar o encaixe da luminária."
    )
    expect(Notification.find_by!(notification_type: "service_completion_issue_reported")).to have_attributes(
      recipient_user_account: account,
      route_params: {"service_job_id" => service_job.id}
    )
    expect(CustomerRecommendation.count).to eq(0)

    post "/api/v1/customer-recommendations/issues",
      params: {token: recommendation_token, message: "   "},
      headers: public_headers("feedback-issue-invalid"),
      as: :json
    expect(response).to have_http_status(:unprocessable_entity)
    assert_api_conform(status: 422)

    post "/api/v1/customer-recommendations/issues",
      params: {token: "invalid", message: "x"},
      headers: public_headers("feedback-issue-missing"),
      as: :json
    expect(response).to have_http_status(:not_found)
    assert_api_conform(status: 404)

    post "/api/v1/customer-recommendations/issues",
      params: {token: recommendation_token, message: "x"},
      headers: {"Origin" => "https://untrusted.example", "X-Request-Id" => "feedback-issue-origin"},
      as: :json
    expect(response).to have_http_status(:forbidden)
    assert_api_conform(status: 403)
  end

  private

  def public_headers(request_id)
    {"Origin" => ENV.fetch("WEB_ORIGIN"), "X-Request-Id" => request_id}
  end

  def session_headers(request_id)
    public_headers(request_id).merge(
      "Cookie" => "#{ApplicationSession::COOKIE_NAME}=#{session_token}"
    )
  end

  def session_read_headers(request_id)
    {
      "X-Request-Id" => request_id,
      "Cookie" => "#{ApplicationSession::COOKIE_NAME}=#{session_token}"
    }
  end
end
