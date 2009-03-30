$:.unshift(File.dirname(__FILE__)) unless
  $:.include?(File.dirname(__FILE__)) || $:.include?(File.expand_path(File.dirname(__FILE__)))

require 'rubygems'
require 'yaml'
require 'xmlsimple'
require 'ftools'
require 'imdb'
require 'mash'
require 'log4r'

require 'dvdprofiler2xbmc/app'
require 'dvdprofiler2xbmc/app_config'
require 'dvdprofiler2xbmc/collection'
require 'dvdprofiler2xbmc/extensions'
require 'dvdprofiler2xbmc/media'
require 'dvdprofiler2xbmc/media_files'
require 'dvdprofiler2xbmc/nfo'
require 'dvdprofiler2xbmc/imdb'

module Dvdprofiler2xbmc
  VERSION = '0.0.5'
end
