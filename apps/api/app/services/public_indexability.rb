# frozen_string_literal: true

# The single place that decides what may be indexed by search engines.
# Nuxt must not re-derive this: it renders whatever Rails reports here as
# the `indexable` field on public responses and emits `noindex` accordingly.
#
# Two independent policies:
#
# - A professional profile is indexable only when it is self-service
#   (never an unclaimed, externally created profile -- indexing those is
#   both a content-quality risk and a privacy question the referral
#   legitimate-interest assessment does not cover) and carries at least one
#   piece of real evidence beyond a bare name and photo.
# - A service x city listing is indexable only once it has enough real
#   supply to be more than a templated shell. Near-identical thin pages are
#   exactly what search engines de-index, and de-indexing drags down the
#   whole domain's quality signal -- so gate before publishing, not after.
class PublicIndexability
  MINIMUM_LISTING_PROFESSIONALS = 3

  def self.listing_indexable?(professional_count)
    professional_count.to_i >= MINIMUM_LISTING_PROFESSIONALS
  end

  # Takes the already-serialized public profile hash (the same one sent to
  # the client) rather than re-querying, so the indexability decision can
  # never drift from what is actually shown on the page.
  def self.profile_indexable?(serialized_profile)
    return false if serialized_profile.nil?
    return false unless serialized_profile[:profile_type] == "self_service"
    return false if serialized_profile[:photo_url].blank?
    return false if serialized_profile[:headline].blank? && serialized_profile[:bio].blank?

    has_portfolio = serialized_profile[:portfolio].present?
    has_recommendation = serialized_profile[:customer_recommendations].present?
    has_verification = serialized_profile[:verification_labels].present?
    has_portfolio || has_recommendation || has_verification
  end
end
