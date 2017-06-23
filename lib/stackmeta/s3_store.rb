# frozen_string_literal: true

require 'aws-sdk'
require 'redis'
require 'redis-namespace'

require 'stackmeta'

module Stackmeta
  class S3Store
    def fetch_tbz2_url(stack: '')
      return nil if stack.to_s.empty?

      cached = urlcache.get(stack)
      return cached if cached

      raw_object = find_raw_tbz2(stack: stack)
      return nil if raw_object.nil?

      urlcache.setex(stack, ttl, raw_object.public_url)
      raw_object.public_url
    end

    private def find_raw_tbz2(stack: '')
      no_tbz2_stack_re = /#{stack.sub(/\.tar\.bz2$/, '')}.*\.tar\.bz2$/
      found = nil

      bucket.objects(prefix: key_prefix).each do |obj|
        if no_tbz2_stack_re.match?(obj.key)
          found = obj
          break
        end
      end

      found
    end

    private def urlcache
      @urlcache ||= Redis::Namespace.new(
        'stackmeta:urlcache', redis: Redis.new
      )
    end

    private def ttl
      @ttl ||= Integer(ENV['STACKMETA_URLCACHE_TTL'] || 3600)
    end

    private def key_prefix
      @key_prefix ||= begin
        ENV['STACKMETA_KEY_PREFIX'] || 'travis-ci/packer-templates'
      end
    end

    private def bucket
      @bucket ||= s3.bucket(bucket_name)
    end

    private def bucket_name
      @bucket_name ||= ENV['STACKMETA_BUCKET_NAME']
    end

    private def s3
      @s3 ||= Aws::S3::Resource.new
    end
  end
end
