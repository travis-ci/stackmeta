# frozen_string_literal: true

require 'csv'

require 'multi_json'

require 'stackmeta'

module Stackmeta
  class DpkgDiffer
    def initialize(finder: nil)
      @finder = finder || Stackmeta::Finder.new
    end

    attr_reader :finder
    private :finder

    def diff(stack_a: nil, stack_b: nil)
      dpkg_manifest_a = MultiJson.load(
        finder.find_item(
          stack: stack_a, item: 'dpkg-manifest.json'
        ) || '{}'
      )
      dpkg_manifest_b = MultiJson.load(
        finder.find_item(
          stack: stack_b, item: 'dpkg-manifest.json'
        ) || '{}'
      )

      ret = {}
      (dpkg_manifest_a.keys | dpkg_manifest_b.keys).sort.each do |package|
        next if package == '__timestamp'
        ret[package] = [dpkg_manifest_a[package], dpkg_manifest_b[package]]
      end

      ret
    end

    def markdown_diff(stack_a: nil, stack_b: nil, updates_only: false)
      ret = [
        "| package | updated | version on #{stack_a} | version on #{stack_b} |",
        '| ------- | ------- | --------------------- | --------------------- |'
      ]
      diff(stack_a: stack_a, stack_b: stack_b).each do |package, versions|
        va = versions.first
        vb = versions.last
        row = "| `#{package}` | #{va != vb ? '✔️' : ''} " \
              "| `#{va || 'N/A'}` | `#{vb || 'N/A'}` |"
        ret << row unless updates_only && va == vb
      end
      ret.join("\n")
    end

    def csv_diff(stack_a: nil, stack_b: nil, updates_only: false)
      rows = [
        ['package', 'updated', "version on #{stack_a}", "version on #{stack_b}"]
      ]
      diff(stack_a: stack_a, stack_b: stack_b).each do |package, versions|
        va = versions.first
        vb = versions.last
        rows << [
          package,
          va != vb ? '✔️' : '',
          va || 'N/A',
          vb || 'N/A'
        ]
      end
      CSV.generate do |csv|
        rows.each do |row|
          csv << row unless updates_only && row[1].empty?
        end
      end
    end
  end
end
