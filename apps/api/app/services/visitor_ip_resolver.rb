# frozen_string_literal: true

require "ipaddr"

class VisitorIpResolver
  def call(request)
    peer_ip = canonical_ip(request.remote_ip)
    return peer_ip if public_ip?(peer_ip)

    railway_ip = request.headers["X-Real-IP"].to_s.strip
    forwarded_ip = canonical_ip(railway_ip) if railway_ip.present?
    return forwarded_ip if forwarded_ip && public_ip?(forwarded_ip)

    peer_ip
  rescue IPAddr::InvalidAddressError
    nil
  end

  private

  def canonical_ip(value)
    address = IPAddr.new(value.to_s)
    address = address.native if address.ipv4_mapped?
    address.to_s
  end

  def public_ip?(value)
    IpLocationService.public_address?(IPAddr.new(value))
  end
end
