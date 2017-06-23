# frozen_string_literal: true

require 'stackmeta'

module Stackmeta
  class Finder
    def initialize(url_func: nil)
      @url_func = url_func || ->(s) { s }
    end

    attr_reader :url_func
    private :url_func

    def find(stack: '')
      return nil if stack.to_s.empty?

      {
        name: 'fake-stack',
        items: {
          'bin-lib.SHA256SUMS' => url_func.call(
            '/fake-stack/bin-lib.SHA256SUMS'
          )
        }
      }
    end

    def find_item(stack: '', item: '')
      return nil if stack.to_s.empty? || item.to_s.empty?

      'lol nah'
    end
  end
end
