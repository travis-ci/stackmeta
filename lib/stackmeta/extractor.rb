# frozen_string_literal: true

require 'pathname'
require 'tempfile'

require 'childprocess'

require 'stackmeta'

module Stackmeta
  class Extractor
    def extract_summary(tbz2_bytes: nil)
      return nil if tbz2_bytes.nil?

      summary = {}

      tar_summary(tbz2_bytes).each do |line|
        parts = line.split
        perms, _, size, _, _, name = parts
        next if perms.start_with?('d')

        name_parts = name.split('/')
        name_parts.shift
        size = Integer(size)
        next if size.zero? || name_parts.empty?

        summary[name_parts.join('/')] = size
      end

      summary
    end

    def extract_item(tbz2_bytes: nil, item: '')
      return nil if tbz2_bytes.nil? || item.strip.empty?
      tar_extract_item(tbz2_bytes, item)
    end

    private def tar_summary(tbz2_bytes)
      tarpipe(
        tbz2_bytes, '-tjvf-', '--strip-components=1'
      ).split(/\n/).map(&:strip)
    end

    private def tar_extract_item(tbz2_bytes, item)
      tarpipe(tbz2_bytes, '--wildcards', '-xjOf-', "*#{item}")
    end

    private def tarpipe(tbz2_bytes, *command)
      process = ChildProcess.build(*([tar] + command))
      tmpout = Tempfile.new('stackmeta-extraction')
      tmpout.sync = true
      process.io.stdout = tmpout
      process.duplex = true
      process.start
      process.io.stdin.write(tbz2_bytes)
      process.io.stdin.close
      process.poll_for_exit(30)
      tmpout.close
      File.read(tmpout.path)
    end

    private def tar
      @tar ||= Stackmeta.config.tar
    end
  end
end
