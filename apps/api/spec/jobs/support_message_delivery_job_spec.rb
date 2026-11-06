# frozen_string_literal: true

require "rails_helper"

RSpec.describe SupportMessageDeliveryJob do
  before { ActionMailer::Base.deliveries.clear }

  let(:message) do
    {"name" => "Ana Souza", "email" => "ana@example.com", "phone" => nil,
     "message" => "Preciso de ajuda com a minha conta.", "topic" => "geral"}
  end

  it "delivers the message with a pinned Message-ID" do
    described_class.perform_now("ops@example.com", message)

    mail = ActionMailer::Base.deliveries.sole
    expect(mail.to).to eq(["ops@example.com"])
    expect(mail.message_id).to match(/\Asupport-\h{16}-\h{12}@berufe\.com\.br\z/)
  end

  it "reports and re-raises provider errors so they can be retried" do
    mailer = class_double(SupportMessageMailer)
    delivery = double("delivery", "message_id=": nil)
    allow(mailer).to receive_message_chain(:with, :received).and_return(delivery)
    allow(delivery).to receive(:deliver_now).and_raise(Berufe::MailDelivery::Rejected)
    allow(Rails.error).to receive(:report)

    expect { described_class.new.perform("ops@example.com", message, mailer:) }
      .to raise_error(Berufe::MailDelivery::Rejected)
    expect(Rails.error).to have_received(:report)
  end
end
