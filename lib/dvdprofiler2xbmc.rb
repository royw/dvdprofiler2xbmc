$:.unshift(File.dirname(__FILE__)) unless
  $:.include?(File.dirname(__FILE__)) || $:.include?(File.expand_path(File.dirname(__FILE__)))

require 'rubygems'
require 'yaml'
require 'xmlsimple'
require 'ftools'
require 'imdb'
require 'mash'
require 'log4r'
require 'ruby-debug'

require 'dvdprofiler2xbmc/app_config'
require 'dvdprofiler2xbmc/extensions'
require 'dvdprofiler2xbmc/controllers/app'
require 'dvdprofiler2xbmc/controllers/nfo_controller'
require 'dvdprofiler2xbmc/models/collection'
require 'dvdprofiler2xbmc/models/dvdprofiler_profile'
require 'dvdprofiler2xbmc/models/imdb_profile'
require 'dvdprofiler2xbmc/models/media'
require 'dvdprofiler2xbmc/models/media_files'
require 'dvdprofiler2xbmc/models/tmdb_profile'
require 'dvdprofiler2xbmc/models/xbmc_info'


module Dvdprofiler2xbmc
  VERSION = '0.0.5'
end
