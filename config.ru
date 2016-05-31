
# Setup so local gems are loaded from `./vendor`.
ENV['BUNDLE_GEMFILE'] ||= "#{ENV['cw_ROOT']}/opt/alces-flight-trigger/Gemfile"
$: << "#{ENV['cw_ROOT']}/opt/alces-flight-trigger/vendor"
require 'rubygems'
require 'bundler'
Bundler.setup(:default)

require './server'
run Server
