# frozen_string_literal: true

require 'base64'

require 'multi_json'
require 'sinatra/base'
require 'sinatra/json'

require 'stackmeta'

module Stackmeta
  class App < Sinatra::Base
    BOOTED_AT = Time.now.utc

    get '/' do
      status 200
      json greeting: 'hello, human',
           uptime: "#{uptime}s"
    end

    get '/:stack' do
      found = finder.find(stack: params[:stack])
      halt 404 if found.nil?
      status 200
      json stack: found,
           :@requested_stack => params[:stack]
    end

    get '/:stack/:item' do
      found = finder.find_item(
        stack: params[:stack], item: params[:item]
      )
      halt 404 if found.nil?
      status 200
      json item: Base64.strict_encode64(found),
           :@encoding => 'base64',
           :@requested_stack => params[:stack],
           :@requested_item => params[:item]
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
  end
end
