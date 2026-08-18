# frozen_string_literal: true

require "rails_helper"

RSpec.describe ProfessionalQuoteSharer do
  self.use_transactional_tests = false

  it "serializes a concurrent first share into one stable lifecycle and bearer" do
    account = UserAccount.create!(
      phone_e164: "+5547999997443",
      role: "professional",
      status: "active"
    )
    profile = ProfessionalProfile.create!(user_account: account, display_name: "Cris Lima")
    revision = profile.working_revision
    revision.update!(status: "approved", reviewed_at: Time.current)
    profile.update!(profile_status: "published", published_revision: revision)
    quote = ProfessionalQuoteWriter.new.call(
      profile:,
      attributes: {
        customer_name: "Cliente",
        service_description: "Serviço concorrente",
        discount_amount: 0,
        items: [{description: "Item", quantity: 1, unit: "serviço", unit_price: 10}]
      }
    )
    ready = Queue.new
    start = Queue.new
    threads = 2.times.map do
      Thread.new do
        ApplicationRecord.connection_pool.with_connection do
          owned_quote = Quote.find(quote.id)
          ready << true
          start.pop
          described_class.new.call(quote: owned_quote).share_url
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
    expect(quote.shared_at).to be_present
  ensure
    if profile
      Quote.where(professional_id: profile.id).delete_all
      ProfessionalDailyActivity.where(professional_id: profile.id).delete_all
      profile.update_columns(
        working_revision_id: nil,
        published_revision_id: nil,
        working_photo_id: nil,
        published_photo_id: nil
      )
      profile.association(:quotes).reset
      profile.destroy!
    end
    account&.destroy!
  end
end
