# frozen_string_literal: true

module Stackmeta
  autoload :App, 'stackmeta/app'
  autoload :Cli, 'stackmeta/cli'
  autoload :Config, 'stackmeta/config'
  autoload :Differ, 'stackmeta/differ'
  autoload :DpkgDiffer, 'stackmeta/dpkg_differ'
  autoload :Extractor, 'stackmeta/extractor'
  autoload :Finder, 'stackmeta/finder'
  autoload :S3Store, 'stackmeta/s3_store'
  autoload :Tarcache, 'stackmeta/tarcache'

  def config
    @config ||= Stackmeta::Config.new
  end

  module_function :config
end
