# frozen_string_literal: true

module Stackmeta
  autoload :App, 'stackmeta/app'
  autoload :Cli, 'stackmeta/cli'
  autoload :Differ, 'stackmeta/differ'
  autoload :Extractor, 'stackmeta/extractor'
  autoload :Finder, 'stackmeta/finder'
  autoload :S3Store, 'stackmeta/s3_store'
  autoload :Tarcache, 'stackmeta/tarcache'
end
