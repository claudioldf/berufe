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
    category_suffix = SecureRandom.hex(4)
    category = ServiceCategory.create!(
      name: "Orçamento concorrente #{category_suffix}",
      slug: "orcamento-concorrente-#{category_suffix}",
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
    profile.working_revision.update!(coverage_city: joinville_city, covers_whole_city: true)
    make_profile_publicly_eligible(profile)
    quote = ProfessionalQuoteWriter.new.call(
      profile:,
      attributes: {
        customer: {
          id: nil,
          name: "Cliente",
          whatsapp_e164: "+5547999912012",
          email: nil
        },
        service_description: "Serviço concorrente",
        valid_until: Date.current + 30.days,
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
      Customer.where(professional_id: profile.id).delete_all
      ProfessionalDailyActivity.where(professional_id: profile.id).delete_all
      ProfessionalDailyMetric.where(professional_id: profile.id).delete_all
      profile.update_columns(
        working_revision_id: nil,
        published_revision_id: nil,
        profile_photo_id: nil
      )
      profile.association(:quotes).reset
      profile.association(:customers).reset
      profile.destroy!
    end
    account&.destroy!
    service&.destroy!
    category&.reload&.destroy!
  end

  context "when the acting session is a delegated administrator session" do
    # Runs inside the ordinary transactional wrapper (unlike the concurrency example
    # above) so the fixtures it creates are rolled back automatically.
    self.use_transactional_tests = true

    it "shares a quote without counting the share against the professional's metrics" do
      account = UserAccount.create!(phone_e164: "+5547999912099", role: "professional", status: "active")
      profile = ProfessionalProfile.create!(user_account: account, display_name: "Cris Delegada")
      make_profile_publicly_eligible(profile)
      quote = ProfessionalQuoteWriter.new.call(
        profile:,
        attributes: {
          customer: {id: nil, name: "Cliente", whatsapp_e164: "+5547999912013", email: nil},
          service_description: "Serviço delegado",
          valid_until: Date.current + 30.days,
          discount_amount: 0,
          items: [{description: "Item", quantity: 1, unit: "serviço", unit_price: 10}]
        }
      )

      Current.application_session = instance_double(ApplicationSession, impersonating?: true)
      result = described_class.new.call(quote:, method: "copy")

      expect(result.share_url).to be_present
      expect(quote.reload).to be_shared
      expect(ProfessionalDailyMetric.where(professional_id: profile.id)).to be_empty
    ensure
      Current.reset
    end
  end
end
