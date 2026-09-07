# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Service adjustments", type: :request, openapi: true do
  let(:account) do
    UserAccount.create!(phone_e164: "+5547999997701", role: "professional", status: "active")
  end
  let(:profile) do
    ProfessionalProfile.create!(
      user_account: account,
      display_name: "Ana Souza",
      whatsapp_e164: account.phone_e164
    )
  end
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
          whatsapp_e164: "+5547999912701",
          email: "marina@example.com"
        },
        pricing_mode: "fixed_price",
        fixed_price_amount: 500,
        service_description: "Pintura da sala",
        service_address: "Rua das Flores, 100",
        scheduled_on: Date.current + 3.days,
        discount_amount: 0,
        valid_until: Date.current + 7.days,
        notes: nil,
        items: [
          {
            description: "Pintura combinada",
            quantity: 1,
            unit: "serviço",
            unit_price: 500
          }
        ],
        customer_supplied_materials: []
      }
    )
  end

  before { make_profile_publicly_eligible(profile) }

  it "records revisioned extras and credits without changing the approved quote" do
    share = ProfessionalQuoteSharer.new.call(quote:, method: "copy")
    token = URI(share.share_url).path.split("/").last
    service_job = SharedQuoteDecisionRecorder.new.call(
      token:,
      decision: "approve",
      revision: quote.reload.lock_version,
      terms_accepted: true,
      message: nil
    )[:service_job]

    post "/api/v1/professional/service-jobs/#{service_job.id}/adjustments",
      params: adjustment_body(
        title: "Parede adicional",
        description: "Pintura de uma parede que não estava no orçamento.",
        schedule_impact: "Acrescenta meio dia de trabalho.",
        items: [
          {
            kind: "additional_service",
            description: "Pintura da parede",
            quantity: 1,
            unit: "parede",
            unit_price: 150,
            media_upload_id: nil
          },
          {
            kind: "credit",
            description: "Crédito por material não utilizado",
            quantity: 1,
            unit: "crédito",
            unit_price: 20,
            media_upload_id: nil
          }
        ]
      ),
      headers: session_headers("adjustment-create"),
      as: :json

    expect(response).to have_http_status(:created)
    adjustment = service_job.service_adjustments.sole
    expect(adjustment).to have_attributes(status: "draft", total_amount: 130)
    expect(response.parsed_body.dig("data", "service_job")).to include(
      "original_total_amount" => "500.00",
      "approved_adjustment_amount" => "0.00",
      "agreed_total_amount" => "500.00",
      "has_unresolved_adjustments" => true
    )
    expect(quote.reload.total_amount).to eq(500)
    assert_api_conform(status: 201)

    post "/api/v1/professional/service-jobs/#{service_job.id}/adjustments/#{adjustment.id}/share",
      params: {share: {method: "copy"}},
      headers: session_headers("adjustment-share"),
      as: :json

    expect(response).to have_http_status(:ok)
    expect(response.parsed_body.dig("data", "share_url")).to include(
      "/orcamento/#{token}#ajuste-#{adjustment.id}"
    )
    adjustment.reload
    expect(adjustment).to be_awaiting_response
    assert_api_conform(status: 200)

    post "/api/v1/shared-service-adjustments/decisions",
      params: {
        token:,
        adjustment_id: adjustment.id,
        decision: {
          kind: "approve",
          revision: adjustment.lock_version + 1,
          terms_accepted: true,
          message: nil
        }
      },
      headers: public_headers("adjustment-stale"),
      as: :json

    expect(response).to have_http_status(:conflict)
    expect(response.parsed_body.dig("error", "code")).to eq("service_adjustment_stale")
    assert_api_conform(status: 409)

    accepted_revision = adjustment.lock_version
    post "/api/v1/shared-service-adjustments/decisions",
      params: {
        token:,
        adjustment_id: adjustment.id,
        decision: {
          kind: "approve",
          revision: accepted_revision,
          terms_accepted: true,
          message: "De acordo."
        }
      },
      headers: public_headers("adjustment-approve"),
      as: :json

    expect(response).to have_http_status(:ok)
    expect(adjustment.reload).to have_attributes(
      status: "approved",
      accepted_revision:,
      accepted_customer_name: "Marina Cliente",
      accepted_customer_phone_e164: "+5547999912701",
      accepted_customer_email: "marina@example.com"
    )
    expect(adjustment.terms_accepted_at).to be_present
    shared_service = response.parsed_body.dig("data", "quote", "service_job")
    expect(shared_service).to include(
      "original_total_amount" => "500.00",
      "approved_adjustment_amount" => "130.00",
      "agreed_total_amount" => "630.00"
    )
    expect(Notification.find_by!(notification_type: "service_adjustment_approved")).to have_attributes(
      recipient_user_account: account,
      route_params: {"service_job_id" => service_job.id}
    )
    expect(quote.reload.total_amount).to eq(500)
    assert_api_conform(status: 200)

    post "/api/v1/professional/service-jobs/#{service_job.id}/adjustments",
      params: adjustment_body(
        title: "Compra já realizada",
        incurred_on: Date.current.iso8601,
        items: [
          {
            kind: "material_reimbursement",
            description: "Tinta adicional",
            quantity: 1,
            unit: "lata",
            unit_price: 80,
            media_upload_id: nil
          }
        ]
      ),
      headers: session_headers("adjustment-create-incurred"),
      as: :json
    expect(response).to have_http_status(:created)
    pending = service_job.service_adjustments.order(:adjustment_number).last
    assert_api_conform(status: 201)

    post "/api/v1/professional/service-jobs/#{service_job.id}/adjustments/#{pending.id}/share",
      params: {share: {method: "whatsapp"}},
      headers: session_headers("adjustment-share-incurred"),
      as: :json
    expect(response).to have_http_status(:ok)
    expect(response.parsed_body.dig("data", "whatsapp_url")).to start_with("https://wa.me/")
    assert_api_conform(status: 200)

    post "/api/v1/professional/service-jobs/#{service_job.id}/complete",
      params: {
        completion: {
          request_recommendation: false,
          acknowledge_open_adjustments: false
        }
      },
      headers: session_headers("service-complete-unacknowledged"),
      as: :json
    expect(response).to have_http_status(:unprocessable_entity)
    expect(response.parsed_body.dig("error", "field_errors")).to have_key(
      "acknowledge_open_adjustments"
    )
    assert_api_conform(status: 422)

    post "/api/v1/professional/service-jobs/#{service_job.id}/complete",
      params: {
        completion: {
          request_recommendation: false,
          acknowledge_open_adjustments: true
        }
      },
      headers: session_headers("service-complete-acknowledged"),
      as: :json
    expect(response).to have_http_status(:ok)
    expect(service_job.reload).to be_completed
    assert_api_conform(status: 200)

    patch "/api/v1/professional/service-jobs/#{service_job.id}/adjustments/#{pending.id}",
      params: adjustment_body(
        revision: pending.reload.lock_version,
        title: "Compra já realizada com detalhes",
        incurred_on: Date.current.iso8601,
        items: [
          {
            kind: "material_reimbursement",
            description: "Tinta adicional",
            quantity: 1,
            unit: "lata",
            unit_price: 80,
            media_upload_id: nil
          }
        ]
      ),
      headers: session_headers("adjustment-update-after-completion"),
      as: :json
    expect(response).to have_http_status(:ok)
    expect(pending.reload).to be_draft
    assert_api_conform(status: 200)

    post "/api/v1/professional/service-jobs/#{service_job.id}/adjustments/#{pending.id}/share",
      params: {share: {method: "copy"}},
      headers: session_headers("adjustment-reshare-after-completion"),
      as: :json
    expect(response).to have_http_status(:ok)
    pending.reload
    assert_api_conform(status: 200)

    post "/api/v1/shared-service-adjustments/decisions",
      params: {
        token:,
        adjustment_id: pending.id,
        decision: {
          kind: "request_change",
          revision: pending.lock_version,
          terms_accepted: false,
          message: "Anexe o comprovante, por favor."
        }
      },
      headers: public_headers("adjustment-request-change-after-completion"),
      as: :json
    expect(response).to have_http_status(:ok)
    expect(pending.reload).to be_change_requested
    expect(pending.service_adjustment_change_requests.sole).to have_attributes(
      message: "Anexe o comprovante, por favor."
    )
    expect(Notification.find_by!(notification_type: "service_adjustment_change_requested")).to have_attributes(
      route_params: {"service_job_id" => service_job.id}
    )
    assert_api_conform(status: 200)

    patch "/api/v1/professional/service-jobs/#{service_job.id}/adjustments/#{pending.id}",
      params: adjustment_body(
        revision: pending.lock_version,
        title: "Compra documentada sem comprovante",
        incurred_on: Date.current.iso8601,
        items: [
          {
            kind: "material_reimbursement",
            description: "Tinta adicional",
            quantity: 1,
            unit: "lata",
            unit_price: 80,
            media_upload_id: nil
          }
        ]
      ),
      headers: session_headers("adjustment-revise-after-change-request"),
      as: :json
    expect(response).to have_http_status(:ok)
    expect(pending.reload).to be_draft
    expect(pending.service_adjustment_change_requests.sole.message).to eq(
      "Anexe o comprovante, por favor."
    )
    assert_api_conform(status: 200)

    post "/api/v1/professional/service-jobs/#{service_job.id}/adjustments",
      params: adjustment_body(title: "Novo depois do encerramento"),
      headers: session_headers("adjustment-create-after-completion"),
      as: :json
    expect(response).to have_http_status(:conflict)
    assert_api_conform(status: 409)

    ProfessionalServiceAdjustmentSharer.new.call(adjustment: pending.reload, method: "copy")
    post "/api/v1/shared-service-adjustments/decisions",
      params: {
        token:,
        adjustment_id: pending.id,
        decision: {
          kind: "approve",
          revision: pending.reload.lock_version,
          terms_accepted: true,
          message: nil
        }
      },
      headers: public_headers("adjustment-approve-after-completion"),
      as: :json
    expect(response).to have_http_status(:ok)
    expect(pending.reload).to be_approved
    expect(response.parsed_body.dig("data", "quote", "service_job", "agreed_total_amount")).to eq(
      "710.00"
    )
    assert_api_conform(status: 200)
  end

  it "rejects a credit that would make the agreed service total negative" do
    share = ProfessionalQuoteSharer.new.call(quote:, method: "copy")
    token = URI(share.share_url).path.split("/").last
    service_job = SharedQuoteDecisionRecorder.new.call(
      token:,
      decision: "approve",
      revision: quote.reload.lock_version,
      terms_accepted: true,
      message: nil
    )[:service_job]
    adjustment = ProfessionalServiceAdjustmentWriter.new.call(
      service_job:,
      attributes: adjustment_body(
        title: "Crédito excessivo",
        items: [
          {
            kind: "credit",
            description: "Crédito",
            quantity: 1,
            unit: "crédito",
            unit_price: 600,
            media_upload_id: nil
          }
        ]
      ).fetch(:adjustment)
    )
    ProfessionalServiceAdjustmentSharer.new.call(adjustment:, method: "copy")

    post "/api/v1/shared-service-adjustments/decisions",
      params: {
        token:,
        adjustment_id: adjustment.id,
        decision: {
          kind: "approve",
          revision: adjustment.reload.lock_version,
          terms_accepted: true,
          message: nil
        }
      },
      headers: public_headers("adjustment-negative-total"),
      as: :json

    expect(response).to have_http_status(:unprocessable_entity)
    expect(adjustment.reload).to be_awaiting_response
    expect(response.parsed_body.dig("error", "field_errors", "base")).to be_present
    assert_api_conform(status: 422)
  end

  it "serves receipt bytes with private response headers" do
    receipt_id = SecureRandom.uuid
    reader = instance_double(SharedServiceAdjustmentReceiptReader)
    allow(SharedServiceAdjustmentReceiptReader).to receive(:new).and_return(reader)
    allow(reader).to receive(:call).and_return(
      SharedServiceAdjustmentReceiptReader::Result.new(
        body: "safe-image",
        content_type: "image/jpeg",
        filename: "berufe-comprovante-#{receipt_id}.jpg"
      )
    )

    post "/api/v1/shared-service-adjustment-receipts/resolve",
      params: {token: QuoteShareToken.issue, receipt_id:},
      headers: public_headers("adjustment-receipt"),
      as: :json

    expect(response).to have_http_status(:ok)
    expect(response.media_type).to eq("image/jpeg")
    expect(response.body).to eq("safe-image")
    expect(response.headers).to include(
      "Cache-Control" => "private, no-store",
      "Referrer-Policy" => "no-referrer",
      "X-Content-Type-Options" => "nosniff"
    )
    assert_api_conform(status: 200)
  end

  it "serves sanitized PNG receipts" do
    receipt_id = SecureRandom.uuid
    reader = instance_double(SharedServiceAdjustmentReceiptReader)
    allow(SharedServiceAdjustmentReceiptReader).to receive(:new).and_return(reader)
    allow(reader).to receive(:call).and_return(
      SharedServiceAdjustmentReceiptReader::Result.new(
        body: "safe-png",
        content_type: "image/png",
        filename: "berufe-comprovante-#{receipt_id}.png"
      )
    )

    post "/api/v1/shared-service-adjustment-receipts/resolve",
      params: {token: QuoteShareToken.issue, receipt_id:},
      headers: public_headers("adjustment-receipt-png"),
      as: :json

    expect(response).to have_http_status(:ok)
    expect(response.media_type).to eq("image/png")
    expect(response.body).to eq("safe-png")
    assert_api_conform(status: 200)
  end

  it "enforces authentication, ownership, origin, validation, and terminal states" do
    share = ProfessionalQuoteSharer.new.call(quote:, method: "copy")
    token = URI(share.share_url).path.split("/").last
    service_job = SharedQuoteDecisionRecorder.new.call(
      token:,
      decision: "approve",
      revision: quote.reload.lock_version,
      terms_accepted: true,
      message: nil
    )[:service_job]
    valid_body = adjustment_body(title: "Serviço extra")

    post "/api/v1/professional/service-jobs/#{service_job.id}/adjustments",
      params: valid_body,
      headers: public_headers("adjustment-create-anonymous"),
      as: :json
    expect(response).to have_http_status(:unauthorized)
    assert_api_conform(status: 401)

    post "/api/v1/professional/service-jobs/#{service_job.id}/adjustments",
      params: valid_body,
      headers: session_headers("adjustment-create-origin").merge("Origin" => "https://untrusted.example"),
      as: :json
    expect(response).to have_http_status(:forbidden)
    assert_api_conform(status: 403)

    post "/api/v1/professional/service-jobs/#{SecureRandom.uuid}/adjustments",
      params: valid_body,
      headers: session_headers("adjustment-create-missing"),
      as: :json
    expect(response).to have_http_status(:not_found)
    assert_api_conform(status: 404)

    post "/api/v1/professional/service-jobs/#{service_job.id}/adjustments",
      params: adjustment_body(title: " "),
      headers: session_headers("adjustment-create-invalid"),
      as: :json
    expect(response).to have_http_status(:unprocessable_entity)
    assert_api_conform(status: 422)

    adjustment = ProfessionalServiceAdjustmentWriter.new.call(
      service_job:,
      attributes: valid_body.fetch(:adjustment)
    )
    update_body = adjustment_body(title: "Serviço extra revisado", revision: adjustment.lock_version)

    patch "/api/v1/professional/service-jobs/#{service_job.id}/adjustments/#{adjustment.id}",
      params: update_body,
      headers: public_headers("adjustment-update-anonymous"),
      as: :json
    expect(response).to have_http_status(:unauthorized)
    assert_api_conform(status: 401)

    patch "/api/v1/professional/service-jobs/#{service_job.id}/adjustments/#{adjustment.id}",
      params: update_body,
      headers: session_headers("adjustment-update-origin").merge("Origin" => "https://untrusted.example"),
      as: :json
    expect(response).to have_http_status(:forbidden)
    assert_api_conform(status: 403)

    patch "/api/v1/professional/service-jobs/#{service_job.id}/adjustments/#{SecureRandom.uuid}",
      params: update_body,
      headers: session_headers("adjustment-update-missing"),
      as: :json
    expect(response).to have_http_status(:not_found)
    assert_api_conform(status: 404)

    patch "/api/v1/professional/service-jobs/#{service_job.id}/adjustments/#{adjustment.id}",
      params: adjustment_body(title: "Versão antiga", revision: adjustment.lock_version + 1),
      headers: session_headers("adjustment-update-stale"),
      as: :json
    expect(response).to have_http_status(:conflict)
    assert_api_conform(status: 409)

    patch "/api/v1/professional/service-jobs/#{service_job.id}/adjustments/#{adjustment.id}",
      params: adjustment_body(title: " ", revision: adjustment.reload.lock_version),
      headers: session_headers("adjustment-update-invalid"),
      as: :json
    expect(response).to have_http_status(:unprocessable_entity)
    assert_api_conform(status: 422)

    share_path = "/api/v1/professional/service-jobs/#{service_job.id}/adjustments/#{adjustment.id}/share"
    post share_path,
      params: {share: {method: "copy"}},
      headers: public_headers("adjustment-share-anonymous"),
      as: :json
    expect(response).to have_http_status(:unauthorized)
    assert_api_conform(status: 401)

    post share_path,
      params: {share: {method: "copy"}},
      headers: session_headers("adjustment-share-origin").merge("Origin" => "https://untrusted.example"),
      as: :json
    expect(response).to have_http_status(:forbidden)
    assert_api_conform(status: 403)

    post "/api/v1/professional/service-jobs/#{service_job.id}/adjustments/#{SecureRandom.uuid}/share",
      params: {share: {method: "copy"}},
      headers: session_headers("adjustment-share-missing"),
      as: :json
    expect(response).to have_http_status(:not_found)
    assert_api_conform(status: 404)

    invalid_sharer = instance_double(ProfessionalServiceAdjustmentSharer)
    allow(ProfessionalServiceAdjustmentSharer).to receive(:new).and_return(invalid_sharer)
    allow(invalid_sharer).to receive(:call).and_raise(
      ProfessionalServiceAdjustmentSharer::InvalidMethod
    )
    post share_path,
      params: {share: {method: "copy"}},
      headers: session_headers("adjustment-share-invalid"),
      as: :json
    expect(response).to have_http_status(:unprocessable_entity)
    assert_api_conform(status: 422)
    allow(ProfessionalServiceAdjustmentSharer).to receive(:new).and_call_original

    cancel_path = "/api/v1/professional/service-jobs/#{service_job.id}/adjustments/#{adjustment.id}/cancel"
    post cancel_path, headers: public_headers("adjustment-cancel-anonymous"), as: :json
    expect(response).to have_http_status(:unauthorized)
    assert_api_conform(status: 401)

    post cancel_path,
      headers: session_headers("adjustment-cancel-origin").merge("Origin" => "https://untrusted.example"),
      as: :json
    expect(response).to have_http_status(:forbidden)
    assert_api_conform(status: 403)

    post "/api/v1/professional/service-jobs/#{service_job.id}/adjustments/#{SecureRandom.uuid}/cancel",
      headers: session_headers("adjustment-cancel-missing"),
      as: :json
    expect(response).to have_http_status(:not_found)
    assert_api_conform(status: 404)

    post cancel_path, headers: session_headers("adjustment-cancel"), as: :json
    expect(response).to have_http_status(:ok)
    assert_api_conform(status: 200)

    post cancel_path, headers: session_headers("adjustment-cancel-again"), as: :json
    expect(response).to have_http_status(:conflict)
    assert_api_conform(status: 409)

    post share_path,
      params: {share: {method: "copy"}},
      headers: session_headers("adjustment-share-terminal"),
      as: :json
    expect(response).to have_http_status(:conflict)
    assert_api_conform(status: 409)

    decision_body = {
      token:,
      adjustment_id: adjustment.id,
      decision: {kind: "decline", revision: adjustment.lock_version, terms_accepted: false, message: nil}
    }
    post "/api/v1/shared-service-adjustments/decisions",
      params: decision_body,
      headers: {"Origin" => "https://untrusted.example", "X-Request-Id" => "adjustment-decision-origin"},
      as: :json
    expect(response).to have_http_status(:forbidden)
    assert_api_conform(status: 403)

    post "/api/v1/shared-service-adjustments/decisions",
      params: decision_body.merge(token: QuoteShareToken.issue),
      headers: public_headers("adjustment-decision-missing"),
      as: :json
    expect(response).to have_http_status(:not_found)
    assert_api_conform(status: 404)

    receipt_body = {token:, receipt_id: SecureRandom.uuid}
    post "/api/v1/shared-service-adjustment-receipts/resolve",
      params: receipt_body,
      headers: {"Origin" => "https://untrusted.example", "X-Request-Id" => "adjustment-receipt-origin"},
      as: :json
    expect(response).to have_http_status(:forbidden)
    assert_api_conform(status: 403)

    post "/api/v1/shared-service-adjustment-receipts/resolve",
      params: receipt_body,
      headers: public_headers("adjustment-receipt-missing"),
      as: :json
    expect(response).to have_http_status(:not_found)
    assert_api_conform(status: 404)
  end

  private

  def adjustment_body(
    title:,
    revision: nil,
    description: nil,
    schedule_impact: nil,
    incurred_on: nil,
    items: []
  )
    adjustment = {
      title:,
      description:,
      schedule_impact:,
      incurred_on:,
      items:
    }
    adjustment[:revision] = revision unless revision.nil?
    {adjustment:}
  end

  def public_headers(request_id)
    {"Origin" => ENV.fetch("WEB_ORIGIN"), "X-Request-Id" => request_id}
  end

  def session_headers(request_id)
    public_headers(request_id).merge(
      "Cookie" => "#{ApplicationSession::COOKIE_NAME}=#{session_token}"
    )
  end
end
