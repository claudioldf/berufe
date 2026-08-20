# frozen_string_literal: true

require "rails_helper"

RSpec.describe ProfessionalQuoteSharer do
  self.use_transactional_tests = false

  it "serializes a concurrent first share into one stable lifecycle and bearer" do
    account = UserAccount.create!(
      phone_e164: "+554799999#{SecureRandom.random_number(10_000).to_s.rjust(4, "0")}",
      role: "professional",
      status: "active"
    )
    profile = ProfessionalProfile.create!(user_account: account, display_name: "Cris Lima")
    category = ServiceCategory.create!(
      name: "Orçamento concorrente",
      slug: "orcamento-concorrente-#{SecureRandom.hex(4)}",
      icon: "i-lucide-wrench",
      is_active: true,
      sort_order: 0
    )
    service = Service.create!(
      category:,
      name: "Serviço concorrente",
      slug: "servico-concorrente-#{SecureRandom.hex(4)}",
      icon: "i-lucide-wrench",
      description: "Serviço usado no teste concorrente.",
      aliases: [],
      is_active: true,
      sort_order: 0
    )
    profile.working_revision.professional_profile_services.create!(service:, is_primary: true)
    profile.working_revision.professional_profile_service_areas.create!(city_code: "Joinville")
    make_profile_publicly_eligible(profile)
    quote = ProfessionalQuoteWriter.new.call(
      profile:,
      attributes: {
        customer_name: "Cliente",
        service_description: "Serviço concorrente",
        discount_amount: 0,
        items: [{description: "Item", quantity: 1, unit: "serviço", unit_price: 10}]
      }
    )
    expect do
      described_class.new.call(quote:, method: "email")
    end.to raise_error(ProfessionalQuoteSharer::InvalidMethod)
    expect(quote.reload).to be_draft
    expect(ProfessionalDailyMetric.where(professional_id: profile.id)).to be_empty
    ready = Queue.new
    start = Queue.new
    threads = 2.times.map do
      Thread.new do
        ApplicationRecord.connection_pool.with_connection do
          owned_quote = Quote.find(quote.id)
          ready << true
          start.pop
          described_class.new.call(quote: owned_quote, method: "copy").share_url
        end
      end
    end

    2.times { ready.pop }
    2.times { start << true }

    urls = threads.map(&:value)
    expect(urls.uniq.one?).to be(true)
    token = URI(urls.first).path.split("/").last
    expect(quote.reload).to be_shared
    expect(quote.share_token_hash).to eq(QuoteShareToken.digest(token))
    expect(QuoteShareToken.decrypt(quote.share_token_ciphertext)).to eq(token)
    expect(quote.shared_at).to be_present
    expect(ProfessionalDailyMetric.find_by!(professional_id: profile.id).quotes_shared).to eq(2)
  ensure
    if profile
      Quote.where(professional_id: profile.id).delete_all
      ProfessionalDailyActivity.where(professional_id: profile.id).delete_all
      ProfessionalDailyMetric.where(professional_id: profile.id).delete_all
      profile.update_columns(
        working_revision_id: nil,
        published_revision_id: nil,
        approved_revision_id: nil,
        working_photo_id: nil,
        published_photo_id: nil,
        approved_photo_id: nil
      )
      profile.association(:quotes).reset
      profile.destroy!
    end
    account&.destroy!
    service&.destroy!
    category&.reload&.destroy!
  end
end
