begin
  require 'spec'
rescue LoadError
  require 'rubygems'
  gem 'rspec'
  require 'spec'
end

$LOAD_PATH.unshift(File.dirname(__FILE__))
$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))

require 'dvdprofiler2xbmc'

TMPDIR = File.join(File.dirname(__FILE__), '../tmp')
SAMPLES_DIR = File.join(File.dirname(__FILE__), 'samples')

require 'read_page_cache'
ReadPageCache.attach_to_classes(SAMPLES_DIR)

Signal.trap("INT") { exit(-1) }

Spec::Runner.configure do |config|

end

