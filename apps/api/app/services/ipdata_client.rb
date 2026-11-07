# frozen_string_literal: true

require "json"
require "net/http"
require "uri"

# Looks up the approximate city, state, and country of a public IP address with
# the ipdata.co API. Only the three fields Berufe needs are requested.
class IpdataClient
  BASE_URL = "https://api.ipdata.co"
  FIELDS = "city,region_code,country_code"

  class LookupError < StandardError; end

  Result = Data.define(:city, :state_code, :country_code)

  def initialize(api_key:, timeout: 2, http: Net::HTTP)
    @api_key = api_key
    @timeout = timeout
    @http = http
  end

  # Returns nil when ipdata has no usable location for the address.
  def lookup(ip_address)
    response = request(ip_address)
    raise LookupError, "ipdata responded with HTTP #{response.code}" unless response.is_a?(Net::HTTPSuccess)

    payload = JSON.parse(response.body)
    result = Result.new(
      city: payload["city"].to_s.squish.presence,
      state_code: payload["region_code"].to_s.squish.presence&.upcase,
      country_code: payload["country_code"].to_s.squish.presence&.upcase
    )
    result if result.to_a.all?
  rescue JSON::ParserError, SystemCallError, Timeout::Error, IOError, OpenSSL::SSL::SSLError => error
    raise LookupError, error.class.name
  end

  private

  def request(ip_address)
    uri = URI("#{BASE_URL}/#{ip_address}")
    uri.query = URI.encode_www_form("api-key" => @api_key, "fields" => FIELDS)

    @http.start(
      uri.host, uri.port,
      use_ssl: true, open_timeout: @timeout, read_timeout: @timeout, write_timeout: @timeout
    ) { |connection| connection.request(Net::HTTP::Get.new(uri, "Accept" => "application/json")) }
  end
end
