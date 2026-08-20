# frozen_string_literal: true

# Kills a shared quote link. The quote returns to `draft` and its token, digest,
# and share timestamp are cleared together, so a link forwarded to the wrong
# person stops resolving immediately. Sharing again issues a new link.
class ProfessionalQuoteRevoker
  class NotShared < StandardError; end

  def call(quote:)
    quote.with_lock do
      raise NotShared unless quote.shared?

      quote.update!(
        status: "draft",
        share_token_hash: nil,
        share_token_ciphertext: nil,
        shared_at: nil
      )
    end
    quote.reload
  end
end
