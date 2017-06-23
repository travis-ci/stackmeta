# frozen_string_literal: true

require 'stackmeta'

module Stackmeta
  class Cli
    def self.run!(argv: ARGV.clone)
      exit(new.run(argv: argv))
    end

    def run(argv: ARGV.clone)
      parser.parse!(argv)
      if argv.empty?
        $stdout.puts parser
        return 1
      end

      stack = argv.shift
      stack_hash = finder.find(stack: stack) || {}

      argv.each do |item|
        found = finder.find_item(stack: stack, item: item)
        next if found.nil?
        stack_hash[:items][item] = Base64.strict_encode64(found)
      end

      stack_hash[:items].keys.each do |key|
        stack_hash[:items][key] = nil unless argv.include?(key)
      end

      $stdout.puts JSON.pretty_generate(stack_hash)
      0
    end

    private def parser
      require 'optparse'
      @parser ||= OptionParser.new do |opts|
        opts.banner = <<~EOF
          Usage: #{File.basename($PROGRAM_NAME)} <stack> [item, item...]

          Fetch stack summary or directly fetch stack item(s).
        EOF
      end
    end

    private def finder
      @finder ||= Stackmeta::Finder.new(
        url_func: ->(*) { nil },
        store: Stackmeta::S3Store.new,
        tarcache: Stackmeta::Tarcache.new,
        extractor: Stackmeta::Extractor.new
      )
    end
  end
end
