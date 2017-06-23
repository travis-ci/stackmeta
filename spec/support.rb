require 'simplecov'

require 'stackmeta'
require 'rspec'
require 'rack/test'

module RackTestBits
  include Rack::Test::Methods

  def app
    Stackmeta::App
  end
end

RSpec.configure do |c|
  c.include RackTestBits
end
