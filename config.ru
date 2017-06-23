# frozen_string_literal: true

libdir = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(libdir) unless $LOAD_PATH.include?(libdir)

require 'stackmeta/app'
run Stackmeta::App
