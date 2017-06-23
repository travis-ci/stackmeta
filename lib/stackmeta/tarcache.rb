# frozen_string_literal: true

require 'base64'
require 'fileutils'
require 'uri'

require 'faraday'

require 'stackmeta'

module Stackmeta
  class Tarcache
    def initialize(expiry: 60 * 60 * 24)
      @expiry = expiry
    end

    attr_reader :expiry
    private :expiry

    def lookup!(url: '')
      return nil if url.empty?

      parsed = URI(url.to_s)
      cached = tbz2cache.get(parsed)
      return Base64.decode64(cached) unless cached.nil?

      bytes = Faraday.get(parsed.to_s).body
      tbz2cache.setex(
        parsed.to_s,
        expiry,
        Base64.strict_encode64(bytes)
      )

      bytes
    rescue => e
      warn e
      nil
    end

    def tbz2cache
      @tbz2cache ||= Redis::Namespace.new(
        'stackmeta:tbz2cache', redis: Redis.new
      )
    end
  end
end
