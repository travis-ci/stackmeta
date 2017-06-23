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
      [
        200,
        { 'Content-Type' => 'application/json' },
        MultiJson.dump(
          greeting: 'hello, human',
          uptime: "#{uptime}s"
        )
      ]
    end

    get '/:stack' do
      halt 400 unless valid_stack?(params[:stack])
      found = finder.find(stack: params[:stack])
      halt 404 if found.nil?
      status 200
      json stack: found,
           :@requested_stack => params[:stack]
    end

    get '/:stack/:item' do
      halt 400 unless valid_stack?(params[:stack])
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

    private def valid_stack?(stack)
      return false if stack.strip.empty?
      # TODO: regexp better
      /.*/.match?(stack)
    end

    private def finder
      @finder ||= Stackmeta::Finder.new(
        url_func: method(:url)
      )
    end
  end
end
