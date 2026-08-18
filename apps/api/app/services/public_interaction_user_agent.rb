# frozen_string_literal: true

class PublicInteractionUserAgent
  AUTOMATION_PATTERN = Regexp.union(
    /bot/i,
    /crawler/i,
    /spider/i,
    /preview/i,
    /facebookexternalhit/i,
    /facebot/i,
    /headlesschrome/i,
    /slackbot/i,
    /whatsapp/i,
    /telegram/i,
    /discordbot/i,
    /curl/i,
    /wget/i
  )

  def self.countable?(user_agent)
    !user_agent.to_s.match?(AUTOMATION_PATTERN)
  end
end
