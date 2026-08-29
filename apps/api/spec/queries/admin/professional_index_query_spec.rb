# frozen_string_literal: true

require "rails_helper"

RSpec.describe Admin::ProfessionalIndexQuery do
  let(:query) { described_class.new }

  let(:unregistered_account) do
    UserAccount.create!(
      phone_e164: "+5547999996001",
      role: "professional",
      status: "active",
      phone_verified_at: Time.current
    )
  end

  let(:draft_profile) do
    account = UserAccount.create!(phone_e164: "+5547999996002", role: "professional", status: "active")
    ProfessionalProfile.create!(user_account: account, display_name: "Carla Rascunho")
  end

  let(:published_profile) do
    account = UserAccount.create!(
      phone_e164: "+5547999996003",
      role: "professional",
      status: "active",
      last_login_at: 1.day.ago,
      login_count: 5
    )
    profile = ProfessionalProfile.create!(user_account: account, display_name: "Ana Souza")
    make_profile_publicly_eligible(profile).tap do |published|
      published.published_revision.update!(whatsapp_e164: "+5547999996013")
    end
  end

  let(:suspended_profile) do
    account = UserAccount.create!(phone_e164: "+5547999996005", role: "professional", status: "active")
    profile = ProfessionalProfile.create!(user_account: account, display_name: "Bruno Lima")
    make_profile_publicly_eligible(profile).tap { |published| published.update!(profile_status: "suspended") }
  end

  before do
    unregistered_account
    draft_profile
    published_profile
    suspended_profile
  end

  it "includes every professional account, including ones without a profile" do
    result = query.call
    ids = result.professionals.pluck(:id)

    expect(ids).to contain_exactly(
      unregistered_account.id,
      draft_profile.user_account_id,
      published_profile.user_account_id,
      suspended_profile.user_account_id
    )
    expect(result.total_count).to eq(4)

    unregistered_row = result.professionals.find { |row| row.id == unregistered_account.id }
    expect(unregistered_row).to have_attributes(
      professional_profile_id: nil,
      display_name: nil,
      profile_status: nil,
      portfolio_count: 0,
      reference_count: 0,
      customer_count: 0,
      quote_count: 0,
      identity_verified: false
    )
  end

  it "computes portfolio, reference, customer, and quote counts, and identity verification" do
    service = published_profile.published_revision.professional_profile_services.first.service
    create_portfolio_item(published_profile, service)
    create_portfolio_item(published_profile, service, deleted: true)
    ProfessionalRelationship.create!(
      initiator_professional: published_profile,
      recipient_professional: suspended_profile,
      relationship_type: "recommendation",
      status: "accepted",
      responded_at: Time.current
    )
    ProfessionalRelationship.create!(
      initiator_professional: draft_profile,
      recipient_professional: published_profile,
      relationship_type: "worked_together",
      status: "pending"
    )
    create_quote(published_profile, number: 1)
    published_profile.verification_requests.create!(
      verification_type: "identity",
      status: "approved",
      submitted_at: Time.current,
      verified_at: Time.current
    )

    row = query.call.professionals.find { |candidate| candidate.id == published_profile.user_account_id }

    expect(row).to have_attributes(
      portfolio_count: 1,
      reference_count: 1,
      customer_count: 1,
      quote_count: 1,
      identity_verified: true,
      city_name: "Joinville",
      state_abbreviation: "SC",
      login_count: 5
    )
  end

  it "filters by name, phone, city, state, identity_verified, and onboarding_finished" do
    published_profile.published_revision.update!(coverage_city: curitiba_city, covers_whole_city: true)

    by_name = query.call(q: "ana souza")
    expect(by_name.professionals.pluck(:id)).to eq([published_profile.user_account_id])

    by_accentless_name = query.call(q: "SOUZA")
    expect(by_accentless_name.professionals.pluck(:id)).to eq([published_profile.user_account_id])

    by_phone = query.call(phone: "47999996003")
    expect(by_phone.professionals.pluck(:id)).to eq([published_profile.user_account_id])

    by_city = query.call(city: curitiba_city.code)
    expect(by_city.professionals.pluck(:id)).to eq([published_profile.user_account_id])

    by_state = query.call(state: "pr")
    expect(by_state.professionals.pluck(:id)).to eq([published_profile.user_account_id])

    finished = query.call(onboarding_finished: "yes")
    expect(finished.professionals.pluck(:id)).to contain_exactly(
      published_profile.user_account_id, suspended_profile.user_account_id
    )

    unfinished = query.call(onboarding_finished: "no")
    expect(unfinished.professionals.pluck(:id)).to contain_exactly(
      unregistered_account.id, draft_profile.user_account_id
    )

    published_profile.verification_requests.create!(
      verification_type: "identity", status: "approved", submitted_at: Time.current, verified_at: Time.current
    )
    verified = query.call(identity_verified: "yes")
    expect(verified.professionals.pluck(:id)).to eq([published_profile.user_account_id])
    not_verified = query.call(identity_verified: "no")
    expect(not_verified.professionals.pluck(:id)).not_to include(published_profile.user_account_id)
  end

  it "summarizes the filtered scope" do
    summary = query.call.summary

    expect(summary).to eq(
      total: 4,
      published: 1,
      suspended: 1,
      onboarding_finished: 2,
      identity_verified: 0
    )
  end

  it "sorts by name ascending and paginates deterministically" do
    all_names = query.call(sort: "name_asc", per_page: 10, page: 1)
    expect(all_names.professionals.pluck(:display_name)).to eq([nil, "Ana Souza", "Bruno Lima", "Carla Rascunho"])

    first_page = query.call(sort: "name_asc", per_page: 2, page: 1)
    second_page = query.call(sort: "name_asc", per_page: 2, page: 2)
    expect(first_page.professionals.pluck(:display_name)).to eq([nil, "Ana Souza"])
    expect(second_page.professionals.pluck(:display_name)).to eq(["Bruno Lima", "Carla Rascunho"])
    expect(first_page.total_pages).to eq(2)
  end

  it "raises Invalid for out-of-range pagination and bad filter values" do
    expect { query.call(page: 0, per_page: 101, city: "abc", state: "brasil", identity_verified: "maybe") }
      .to raise_error(described_class::Invalid) do |error|
        expect(error.field_errors.keys).to contain_exactly(:page, :per_page, :city, :state, :identity_verified)
      end
  end

  private

  def create_portfolio_item(profile, service, deleted: false)
    upload = MediaUpload.create!(
      professional_profile: profile,
      purpose: "portfolio_image",
      state: "processed",
      declared_content_type: "image/png",
      declared_byte_size: 120,
      actual_content_type: "image/png",
      sanitized_content_type: "image/png",
      actual_byte_size: 120,
      sanitized_byte_size: 100,
      width: 640,
      height: 380,
      quarantine_key: "quarantine/#{profile.id}/#{SecureRandom.uuid}",
      sanitized_key: "sanitized/#{profile.id}/#{SecureRandom.uuid}.png",
      authorization_expires_at: 5.minutes.from_now,
      uploaded_at: 1.minute.ago,
      processed_at: Time.current
    )
    profile.portfolio_items.create!(
      media_upload: upload,
      service:,
      title: "Trabalho",
      status: "approved",
      private_key: upload.sanitized_key,
      content_type: "image/png",
      byte_size: 100,
      width: 640,
      height: 380,
      submitted_at: Time.current,
      deleted_at: deleted ? Time.current : nil
    )
  end

  def create_quote(profile, number:)
    customer = profile.customers.create!(name: "Cliente #{number}", whatsapp_e164: "+554799999#{number.to_s.rjust(4, "0")}")
    profile.quotes.create!(
      customer:,
      quote_number: number,
      customer_name: customer.name,
      customer_phone_e164: customer.whatsapp_e164,
      service_description: "Serviço #{number}",
      status: "draft",
      discount_amount: 0,
      quote_items: [
        QuoteItem.new(description: "Serviço", quantity: 1, unit: "serviço", unit_price: 100, sort_order: 0)
      ]
    )
  end
end
