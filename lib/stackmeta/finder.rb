# frozen_string_literal: true

require 'stackmeta'

module Stackmeta
  class Finder
    def initialize(extractor: nil, store: nil, tarcache: nil, url_func: nil)
      @extractor = extractor || Stackmeta::Extractor.new
      @store = store || Stackmeta::S3Cache.new
      @tarcache = tarcache || Stackmeta::Tarcache.new
      @url_func = url_func || ->(_stack, item) { item }
    end

    attr_reader :extractor, :store, :tarcache, :url_func
    private :extractor
    private :store
    private :tarcache
    private :url_func

    def find(stack: '')
      return nil if stack.to_s.empty?

      summary = extractor.extract_summary(
        tbz2_bytes: tarcache.lookup!(
          url: store.fetch_tbz2_url(stack: stack)
        )
      )

      return nil if summary.nil?

      ret = { name: stack, items: {} }
      summary.keys.each do |filename|
        ret[:items][filename] = url_func.call(
          stack, File.basename(filename)
        )
      end

      ret
    end

    def find_item(stack: '', item: '')
      return nil if stack.to_s.empty? || item.to_s.empty?

      extractor.extract_item(
        tbz2_bytes: tarcache.lookup!(
          url: store.fetch_tbz2_url(stack: stack)
        ),
        item: item
      )
    end
  end
end
