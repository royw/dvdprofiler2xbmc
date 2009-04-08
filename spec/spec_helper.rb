begin
  require 'spec'
rescue LoadError
  require 'rubygems'
  gem 'rspec'
  require 'spec'
end

$:.unshift(File.dirname(__FILE__) + '/../lib')
require 'dvdprofiler2xbmc'

require File.dirname(__FILE__) + '/cache_extensions'

TMPDIR = File.join(File.dirname(__FILE__), '../tmp')

SAMPLES_DIR = File.join(File.dirname(__FILE__), 'samples')

Signal.trap("INT") { exit(-1) }
