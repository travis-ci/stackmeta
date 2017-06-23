# frozen_string_literal: true

require 'base64'

require 'multi_json'
require 'sinatra/base'
require 'sinatra/contrib'

require 'stackmeta'

module Stackmeta
  class App < Sinatra::Base
    BOOTED_AT = Time.now.utc

    register Sinatra::Contrib

    get '/' do
      status 200
      json greeting: 'hello, human',
           uptime: "#{uptime}s"
    end

    get '/:stack' do
      found = finder.find(stack: params[:stack])
      halt 404 if found.nil?

      respond_to do |f|
        f.json do
          json stack: found,
               :@requested_stack => params[:stack]
        end

        f.txt do
          hacked_md = ["# #{found[:name]}"]
          found[:items].each do |filename, url|
            hacked_md << "- [#{filename}](#{url})"
          end
          body hacked_md.join("\n")
        end
      end
    end

    get '/diff/:stack_a/:stack_b' do
      diff = differ.diff_items(
        items: Array(params[:item]),
        stack_a: params[:stack_a],
        stack_b: params[:stack_b]
      )

      respond_to do |f|
        f.json do
          json diff: diff,
               :@stack_a => params[:stack_a],
               :@stack_b => params[:stack_b],
               :@item => Array(params[:item])
        end

        f.txt do
          body diff.values.join("\n")
        end
      end
    end

    get '/:stack/:item' do
      found = finder.find_item(
        stack: params[:stack], item: params[:item]
      )
      halt 404 if found.nil?

      respond_to do |f|
        f.json do
          json item: Base64.strict_encode64(found),
               :@encoding => 'base64',
               :@requested_stack => params[:stack],
               :@requested_item => params[:item]
        end

        f.txt { body found }
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
  end
end
