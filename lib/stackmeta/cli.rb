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

      return run_diff(argv) if argv.first == 'diff'

      stack = argv.shift
      stack_hash = finder.find(stack: stack)
      return 1 if stack_hash.nil?

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

    private def run_diff(argv)
      if argv.length < 3
        $stdout.puts parser
        return 2
      end

      argv.shift
      stack_a = argv.shift
      stack_b = argv.shift

      diff = differ.diff_items(
        items: Array(argv),
        stack_a: stack_a,
        stack_b: stack_b
      )

      $stdout.puts JSON.pretty_generate(diff: diff)
      0
    end

    private def parser
      require 'optparse'
      prog = File.basename($PROGRAM_NAME)
      @parser ||= OptionParser.new do |opts|
        opts.banner = <<~EOF
          Usage: #{prog} [diff] <stack> [stack] [item, item...]

          Fetch stack summary, directly fetch stack item(s), or diff arbitrary
          items between stacks.


          EXAMPLES:

          Fetch stack summary:

            #{prog} sugilite-trusty-1498161108

          Fetch stack items:

            #{prog} sugilite-trusty-1498161108 \\
                    dpkg-manifest.json \\
                    TRAVIS_UID

          Diff stack items:

            #{prog} diff \\
                    sugilite-trusty-1480960799 \\
                    sugilite-trusty-1498161108 \\
                    dpkg-manifest.json
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

    private def differ
      @differ ||= Stackmeta::Differ.new(finder: finder)
    end
  end
end
