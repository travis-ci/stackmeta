# frozen_string_literal: true

require 'childprocess'

require 'stackmeta'

module Stackmeta
  class Differ
    def initialize(finder: nil)
      @finder = finder || Stackmeta::Finder.new
    end

    attr_reader :finder
    private :finder

    def diff_items(items: [], stack_a: nil, stack_b: nil)
      return {} if items.empty? || stack_a.nil? || stack_b.nil?

      ret = {}
      items.each do |item|
        ret[item] = diff_item(item: item, stack_a: stack_a, stack_b: stack_b)
      end

      ret
    end

    def diff_item(item: '', stack_a: nil, stack_b: nil)
      return '' if item.to_s.empty? || stack_a.nil? || stack_b.nil?

      item_a_bytes = finder.find_item(
        stack: stack_a,
        item: item
      )

      item_a_bytes = '' if item_a_bytes.nil?

      item_b_bytes = finder.find_item(
        stack: stack_b,
        item: item
      )

      item_b_bytes = '' if item_b_bytes.nil?

      return '' if item_a_bytes.empty? && item_b_bytes.empty?

      diff_bytes(
        label: item,
        stack_a: stack_a, stack_b: stack_b,
        a: item_a_bytes, b: item_b_bytes
      )
    end

    private def diff_bytes(label: '', stack_a: '', stack_b: '', a: '', b: '')
      tmp_a = Tempfile.new('stackmeta-diff-a')
      tmp_a.write(a)
      tmp_a.close

      tmp_b = Tempfile.new('stackmeta-diff-b')
      tmp_b.write(b)
      tmp_b.close

      process = ChildProcess.build(
        'diff', '-u',
        '--label', "a/#{label}",
        tmp_a.path,
        '--label', "b/#{label}",
        tmp_b.path
      )

      tmpout = Tempfile.new('stackmeta-diff')
      tmpout.sync = true

      process.io.stdout = tmpout
      process.start
      process.poll_for_exit(30)
      tmpout.close

      diff_body = File.read(tmpout.path)
      return '' if diff_body.strip.empty?
      <<~EOF + diff_body
        diff a/#{label} b/#{label}
        #{stack_a}..#{stack_b}
      EOF
    end
  end
end
