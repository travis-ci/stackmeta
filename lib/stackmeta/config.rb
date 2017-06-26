# frozen_string_literal: true

require 'stackmeta'

module Stackmeta
  class Config
    class << self
      def cfg(method_name, default, cast: nil)
        define_method(method_name) do
          env(
            method_name.to_s.upcase.delete('?'),
            default,
            cast: cast
          )
        end
      end
    end

    cfg :redis_rack_cache?, false,
        cast: ->(v) { %w[yes on true 1].include?(v.to_s.strip.downcase) }
    cfg :redis_url, 'redis://127.0.0.1:6379'
    cfg :s3_store_key_prefix, 'travis-ci/packer-templates'
    cfg :s3_store_bucket_name, ''
    cfg :tar, 'tar'
    cfg :urlcache_ttl, 3600, cast: ->(v) { Integer(v) }

    def env(subkey, default, cast: nil)
      value = ENV["STACKMETA_#{subkey}"] || default
      return cast.call(value) unless cast.nil?
      value
    end
  end
end
