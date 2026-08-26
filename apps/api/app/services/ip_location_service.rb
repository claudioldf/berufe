# frozen_string_literal: true

require "ipaddr"

class IpLocationService
  SUCCESS_TTL = 24.hours
  FAILURE_TTL = 5.minutes
  NON_PUBLIC_NETWORKS = %w[
    0.0.0.0/8
    10.0.0.0/8
    100.64.0.0/10
    127.0.0.0/8
    169.254.0.0/16
    172.16.0.0/12
    192.0.0.0/24
    192.0.2.0/24
    192.168.0.0/16
    198.18.0.0/15
    198.51.100.0/24
    203.0.113.0/24
    224.0.0.0/4
    240.0.0.0/4
    ::/128
    ::1/128
    100::/64
    2001:db8::/32
    fc00::/7
    fe80::/10
    ff00::/8
  ].map { |network| IPAddr.new(network) }.freeze

  Location = Data.define(:city, :state_code, :country_code)

  def self.public_address?(address)
    normalized = address.ipv4_mapped? ? address.native : address
    NON_PUBLIC_NETWORKS.none? { |network| network.include?(normalized) }
  end

  def initialize(
    client: Rails.application.config.x.berufe.maxmind_client,
    cache: Rails.application.config.x.berufe.ip_location_cache
  )
    @client = client
    @cache = cache
  end

  def call(ip_address)
    address = IPAddr.new(ip_address.to_s)
    address = address.native if address.ipv4_mapped?
    return unless self.class.public_address?(address)
    return unless client

    key = cache_key(address.to_s)
    cached = cache.read(key)
    return deserialize(cached) if cached

    location = lookup(address.to_s)
    cache.write(
      key,
      serialize(location),
      expires_in: location ? SUCCESS_TTL : FAILURE_TTL
    )
    location
  rescue IPAddr::InvalidAddressError
    nil
  end

  private

  attr_reader :client, :cache

  def lookup(ip_address)
    record = client.city(ip_address)
    city = record.city.name.to_s.squish.presence
    state_code = record.most_specific_subdivision.iso_code.to_s.squish.presence&.upcase
    country_code = record.country.iso_code.to_s.squish.presence&.upcase
    return unless city && state_code && country_code

    Location.new(city:, state_code:, country_code:)
  rescue MaxMind::GeoIP2::AddressInvalidError,
    MaxMind::GeoIP2::AddressNotFoundError,
    MaxMind::GeoIP2::AddressReservedError
    nil
  rescue => error
    Rails.logger.warn("maxmind_lookup_failed class=#{error.class} request_id=#{Current.request_id}")
    nil
  end

  def cache_key(ip_address)
    "ip-location:#{SessionSecurityDigest.call(purpose: "ip_location", value: ip_address)}"
  end

  def serialize(location)
    location ? {found: true, location: location.to_h} : {found: false}
  end

  def deserialize(value)
    return unless value[:found]

    Location.new(**value.fetch(:location).symbolize_keys)
  end
end
