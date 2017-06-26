# frozen_string_literal: true

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
      if Stackmeta.config.redis_rack_cache?
        require 'rack/cache'
        require 'redis-rack-cache'

        redis_url = Stackmeta.config.redis_url
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

      cache_control :public, max_age: THIRTY_DAYS_IN_SECONDS
      headers 'Vary' => 'Accept, Accept-Encoding'

      params[:items] = to_string_array(params[:items])
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

      Array(params[:items]).each do |item|
        found_item = finder.find_item(
          stack: params[:stack], item: item
        )

        next if found_item.nil?

        found[:items_expanded] ||= {}
        found[:items_expanded][item] = found_item
      end

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
            if found.key?(:items_expanded) &&
               found[:items_expanded].key?(filename)
              hacked_md << "- [#{filename}](##{filename})"
              next
            end
            hacked_md << "- [#{filename}](#{url})"
          end

          (found[:items_expanded] || {}).each do |filename, content|
            if filename.match?(/\.json$/)
              content = MultiJson.dump(MultiJson.load(content), pretty: true)
            end

            hacked_md << <<~EOF

              ## #{filename}

              \`\`\`
              #{content}
              \`\`\`
            EOF
          end

          body_with_etag(hacked_md.join("\n"))
        end
      end
    end

    get '/diff/:stack_a/:stack_b' do
      diff = differ.diff_items(
        items: params[:items],
        stack_a: params[:stack_a],
        stack_b: params[:stack_b]
      )

      respond_to do |f|
        f.json do
          body_with_etag(MultiJson.dump(
                           diff: diff,
                           :@stack_a => params[:stack_a],
                           :@stack_b => params[:stack_b],
                           :@items => params[:items]
          ))
        end

        f.txt do
          body_with_etag(diff.values.join("\n"))
        end
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

    private def to_string_array(str)
      str.to_s.split(',').map(&:strip)
    end
  end
end
