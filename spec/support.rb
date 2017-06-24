# frozen_string_literal: true

require 'simplecov'

require 'stackmeta'
require 'rspec'
require 'rack/test'

ENV['STACKMETA_REDIS_RACK_CACHE'] = nil

module RackTestBits
  include Rack::Test::Methods

  def app
    Stackmeta::App
  end
end

RSpec.configure do |c|
  c.include RackTestBits
end
