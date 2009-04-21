$:.unshift(File.dirname(__FILE__)) unless
  $:.include?(File.dirname(__FILE__)) || $:.include?(File.expand_path(File.dirname(__FILE__)))

require 'rubygems'
require 'yaml'
require 'xmlsimple'
require 'ftools'
require 'mash'
require 'log4r'

# royw gems on github
require 'imdb'
require 'tmdb'
require 'dvdprofiler_collection'
require 'roys_extensions'

# local files
require 'dvdprofiler2xbmc/app_config'
require 'dvdprofiler2xbmc/controllers/app'
require 'dvdprofiler2xbmc/controllers/fanart_controller'
require 'dvdprofiler2xbmc/controllers/nfo_controller'
require 'dvdprofiler2xbmc/controllers/thumbnail_controller'
require 'dvdprofiler2xbmc/models/dvdprofiler_info'
require 'dvdprofiler2xbmc/models/imdb_info'
require 'dvdprofiler2xbmc/models/tmdb_info'
require 'dvdprofiler2xbmc/models/media'
require 'dvdprofiler2xbmc/models/media_files'
require 'dvdprofiler2xbmc/models/xbmc_info'

TMDB_API_KEY = '7a2f6eb9b6aa01651000f0a9324db835'

