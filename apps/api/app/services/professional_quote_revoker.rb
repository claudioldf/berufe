# frozen_string_literal: true

# Kills a shared quote link. The quote returns to `saved` and its token, digest,
# and share timestamp are cleared together, so a link forwarded to the wrong
# person stops resolving immediately. Sharing again issues a new link.
class ProfessionalQuoteRevoker
  class NotShared < StandardError; end

  def call(quote:)
    quote.with_lock do
      raise NotShared if quote.draft? || quote.saved? || quote.locked_for_editing?

      quote.update!(
        status: "saved",
        share_token_hash: nil,
        share_token_ciphertext: nil,
        shared_at: nil,
        customer_decided_at: nil,
        customer_decision_message: nil,
        terms_accepted_at: nil
      )
    end
    quote.reload
  end
end
