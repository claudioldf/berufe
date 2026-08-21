# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Professional quote numbering" do
  self.use_transactional_tests = false

  it "serializes concurrent creates into unique owner-scoped numbers" do
    account = UserAccount.create!(
      phone_e164: "+5547999997412",
      role: "professional",
      status: "active"
    )
    profile = ProfessionalProfile.create!(user_account: account, display_name: "Beto Lima")
    ready = Queue.new
    start = Queue.new
    threads = 2.times.map do |index|
      Thread.new do
        ApplicationRecord.connection_pool.with_connection do
          owned_profile = ProfessionalProfile.find(profile.id)
          ready << true
          start.pop
          ProfessionalQuoteWriter.new.call(
            profile: owned_profile,
            attributes: {
              customer: {
                id: nil,
                name: "Cliente #{index}",
                whatsapp_e164: "+55479999120#{index.to_s.rjust(2, "0")}",
                email: nil
              },
              service_description: "Serviço concorrente",
              discount_amount: 0,
              valid_until: nil,
              notes: nil,
              items: [
                {description: "Item", quantity: 1, unit: "serviço", unit_price: 10}
              ]
            }
          ).quote_number
        end
      end
    end

    2.times { ready.pop }
    2.times { start << true }

    expect(threads.map(&:value).sort).to eq([1, 2])
    expect(profile.quotes.pluck(:quote_number).sort).to eq([1, 2])
  ensure
    if profile
      Quote.where(professional_id: profile.id).delete_all
      Customer.where(professional_id: profile.id).delete_all
      ProfessionalDailyActivity.where(professional_id: profile.id).delete_all
      profile.update_columns(
        working_revision_id: nil,
        published_revision_id: nil,
        working_photo_id: nil,
        published_photo_id: nil
      )
      profile.destroy!
    end
    account&.destroy!
  end
end
