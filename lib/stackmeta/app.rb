# frozen_string_literal: true

require 'base64'
require 'digest/sha1'

require 'multi_json'
require 'rack/deflater'
require 'sinatra/base'
require 'sinatra/contrib'

require 'stackmeta'

module Stackmeta
  class App < Sinatra::Base
    BOOTED_AT = Time.now.utc
    THIRTY_DAYS_IN_SECONDS = 2_592_000

    register Sinatra::Contrib

    configure do
      if ENV['STACKMETA_REDIS_RACK_CACHE']
        require 'rack/cache'
        require 'redis-rack-cache'

        redis_url = ENV['REDIS_URL'] || 'redis://127.0.0.1:6379'
        use Rack::Cache,
            metastore: File.join(
              redis_url, '0/stackmeta:rack-cache:metastore'
            ),
            entitystore: File.join(
              redis_url, '0/stackmeta:rack-cache:entitystore'
            )
      end

      use Rack::Deflater
    end

    before do
      env['HTTP_ACCEPT'] = {
        'text' => 'text/plain',
        'json' => 'application/json'
      }.fetch(params[:format], env['HTTP_ACCEPT'])
    end

    get '/' do
      cache_control :public, :no_cache
      status 200
      json greeting: 'hello, human',
           uptime: "#{uptime}s"
    end

    get '/:stack' do
      found = finder.find(stack: params[:stack])
      halt 404 if found.nil?

      cache_control :public, max_age: THIRTY_DAYS_IN_SECONDS

      respond_to do |f|
        f.json do
          body_with_etag(MultiJson.dump(
                           stack: found,
                           :@requested_stack => params[:stack]
          ))
        end

        f.txt do
          hacked_md = ["# #{found[:name]}"]
          found[:items].each do |filename, url|
            hacked_md << "- [#{filename}](#{url})"
          end
          body_with_etag(hacked_md.join("\n"))
        end
      end
    end

    get '/diff/:stack_a/:stack_b' do
      params[:item] = params[:item].to_s.split(',').map(&:strip)

      diff = differ.diff_items(
        items: params[:item],
        stack_a: params[:stack_a],
        stack_b: params[:stack_b]
      )

      cache_control :public, max_age: THIRTY_DAYS_IN_SECONDS

      respond_to do |f|
        f.json do
          body_with_etag(MultiJson.dump(
                           diff: diff,
                           :@stack_a => params[:stack_a],
                           :@stack_b => params[:stack_b],
                           :@item => params[:item]
          ))
        end

        f.txt do
          body_with_etag(diff.values.join("\n"))
        end
      end
    end

    get '/:stack/:item' do
      found = finder.find_item(
        stack: params[:stack], item: params[:item]
      )
      halt 404 if found.nil?

      cache_control :public, max_age: THIRTY_DAYS_IN_SECONDS

      respond_to do |f|
        f.json do
          body_with_etag(MultiJson.dump(
                           item: Base64.strict_encode64(found),
                           :@encoding => 'base64',
                           :@requested_stack => params[:stack],
                           :@requested_item => params[:item]
          ))
        end

        f.txt { body_with_etag(found) }
      end
    end

    private def uptime
      Time.now.utc - BOOTED_AT
    end

    private def finder
      @finder ||= Stackmeta::Finder.new(
        url_func: ->(stack, item) { url("#{stack}/#{item}") },
        store: Stackmeta::S3Store.new,
        extractor: Stackmeta::Extractor.new
      )
    end

    private def differ
      @differ ||= Stackmeta::Differ.new(finder: finder)
    end

    private def body_with_etag(str)
      Digest::SHA1.hexdigest(str)
      body str
    end
  end
end
