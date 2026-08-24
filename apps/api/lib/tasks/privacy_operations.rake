# frozen_string_literal: true

namespace :privacy do
  desc "Verify, unpublish, and enqueue erasure of a professional account"
  task request_professional_erasure: :environment do
    print "Verified professional phone (+55...): "
    phone = $stdin.gets&.strip
    print "Support ticket reference: "
    ticket_reference = $stdin.gets&.strip

    request_record = ProfessionalDataErasureRequester.new.call(
      phone_e164: phone,
      ticket_reference:
    )
    puts "Erasure request #{request_record.id} accepted; the profile is unpublished and erasure is queued."
  rescue ProfessionalDataErasureRequester::NotFound
    abort "No eligible professional account was found."
  rescue ProfessionalDataErasureRequester::VerificationRequired
    abort "A successful SMS login in the last 30 minutes is required."
  end

  desc "Withdraw publication consent for one customer recommendation"
  task withdraw_recommendation: :environment do
    print "Professional profile slug: "
    profile_slug = $stdin.gets&.strip
    print "Recommendation author email: "
    email = $stdin.gets&.strip

    recommendation = CustomerRecommendationPublicationWithdrawer.new.call(profile_slug:, email:)
    puts "Recommendation #{recommendation.id} is no longer public."
  rescue CustomerRecommendationPublicationWithdrawer::NotFound
    abort "No published recommendation matched the verified request."
  end
end
