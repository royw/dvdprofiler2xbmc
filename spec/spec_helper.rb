begin
  require 'spec'
rescue LoadError
  require 'rubygems'
  gem 'rspec'
  require 'spec'
end

$:.unshift(File.dirname(__FILE__) + '/../lib')
require 'dvdprofiler2xbmc'

TMPDIR = File.join(File.dirname(__FILE__), '../tmp')

SAMPLES_DIR = File.join(File.dirname(__FILE__), 'samples')

# Kernel.html_cache_dir = 'spec/samples'

