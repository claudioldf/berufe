# frozen_string_literal: true

require "uri"

class SocialProfileUrl
  class Invalid < StandardError; end

  PLATFORMS = %i[instagram youtube].freeze
  HOSTS = {
    instagram: %w[instagram.com www.instagram.com m.instagram.com],
    youtube: %w[youtube.com www.youtube.com m.youtube.com]
  }.freeze
  INSTAGRAM_HANDLE = /\A[A-Za-z0-9._]{1,30}\z/
  YOUTUBE_HANDLE = /\A[\p{L}\p{N}._-]{3,30}\z/

  def self.normalize(value, platform:)
    new(platform:).normalize(value)
  end

  def self.canonical?(value, platform:)
    return true if value.blank?

    normalize(value, platform:) == value
  rescue Invalid
    false
  end

  def initialize(platform:)
    @platform = platform.to_sym
    raise ArgumentError, "unknown social platform" unless PLATFORMS.include?(@platform)
  end

  def normalize(value)
    candidate = value.to_s.strip
    return nil if candidate.empty?

    handle = looks_like_url?(candidate) ? handle_from_url(candidate) : candidate.delete_prefix("@")
    raise Invalid unless valid_handle?(handle)

    canonical_url(handle)
  rescue URI::InvalidURIError
    raise Invalid
  end

  private

  attr_reader :platform

  def looks_like_url?(candidate)
    candidate.match?(%r{\Ahttps?://}i) || candidate.include?("/") || HOSTS.fetch(platform).include?(candidate.downcase)
  end

  def handle_from_url(candidate)
    uri = URI.parse(candidate.match?(%r{\Ahttps?://}i) ? candidate : "https://#{candidate}")
    raise Invalid unless uri.is_a?(URI::HTTP)
    raise Invalid unless HOSTS.fetch(platform).include?(uri.host.to_s.downcase)
    raise Invalid if uri.userinfo.present? || uri.port != 443 && uri.port != 80

    segments = uri.path.split("/").reject(&:empty?)
    raise Invalid unless segments.one?

    segment = segments.first
    return segment if platform == :instagram
    return segment.delete_prefix("@") if segment.start_with?("@")

    raise Invalid
  end

  def valid_handle?(handle)
    pattern = (platform == :instagram) ? INSTAGRAM_HANDLE : YOUTUBE_HANDLE
    handle.match?(pattern)
  end

  def canonical_url(handle)
    if platform == :instagram
      "https://www.instagram.com/#{handle}/"
    else
      "https://www.youtube.com/@#{handle}"
    end
  end
end
