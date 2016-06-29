
alces_flight_trigger_dir = "#{ENV['cw_ROOT']}/opt/alces-flight-trigger"

# Setup so local gems are loaded from `./vendor`.
ENV['BUNDLE_GEMFILE'] ||= "#{alces_flight_trigger_dir}/Gemfile"
$: << "#{alces_flight_trigger_dir}/vendor"
require 'rubygems'
require 'bundler'
Bundler.setup(:default)

require "#{alces_flight_trigger_dir}/server"
run Server
