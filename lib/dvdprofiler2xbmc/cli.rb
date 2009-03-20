require 'rubygems'
require 'yaml'
require 'xmlsimple'
require 'ftools'
require 'imdb'
require 'pp'
require 'mash'
require 'log4r'
require 'commandline/optionparser'
include CommandLine

require 'dvdprofiler2xbmc/app'
require 'dvdprofiler2xbmc/app_config'
require 'dvdprofiler2xbmc/collection'
require 'dvdprofiler2xbmc/extensions'
require 'dvdprofiler2xbmc/imdb_extensions'
require 'dvdprofiler2xbmc/media'
require 'dvdprofiler2xbmc/media_files'
require 'dvdprofiler2xbmc/nfo'

module Dvdprofiler2xbmc
  # == Synopsis
  # Command line exit codes
  class ExitCode
    UNKNOWN = 3
    CRITICAL = 2
    WARNING = 1
    OK = 0
  end

  class CLI
    include AppConfig

    def self.execute(stdout, arguments=[])
      exit_code = ExitCode::OK
      
      # we start a STDOUT logger, but it will be switched after 
      # the config files are read if config[:logger_output] is set
      logger = Log4r::Logger.new('dvdprofiler2xbmc')
      logger.outputters = Log4r::StdoutOutputter.new(:console)
      logger.level = Log4r::DEBUG
      
      begin
	# trap ^C interrupts and let the app instance cleanly exit any long loops
	Signal.trap("INT") {DvdProfiler2Xbmc.interrupt}

	
	# parse the command line
	options = setupParser()
	od = options.parse(arguments)

	# load config values
	AppConfig.default
	
	# the first reinitialize_logger adds the command line logging options to the default config
	# then we load the config files
	# then we run reinitialize_logger again to modify the logger for any logging options from the config files
	
	reinitialize_logger(logger, od["--quiet"], od["--debug"])
	AppConfig.load
# 	  AppConfig[:pretend] = od["--pretend"]
	AppConfig[:imdb_query] = !od["--no_imdb_query"]
	AppConfig.save
	reinitialize_logger(logger, od["--quiet"], od["--debug"])
	  
	unless od["--help"] || od["--version"]
	  # create and execute class instance here
	  app = DvdProfiler2Xbmc.new
	  app.execute
	  app.report.each {|line| puts line}
	end
      rescue Exception => eMsg
	logger.error {eMsg.to_s}
	logger.error {options.to_s}
	logger.error {eMsg.backtrace.join("\n")}
	exit_code = ExitCode::CRITICAL
      end
      exit_code
    end

    # Setup the command line option parser
    # Returns:: OptionParser instances
    def self.setupParser()
      options = OptionParser.new()
      options << Option.new(:flag, :names => %w(--help -h), 
			    :opt_found => lambda {Log4r::Logger['dvdprofiler2xbmc'].info{options.to_s}}, 
			    :opt_description => "This usage information")
      options << Option.new(:flag, :names => %w(--version -v), 
			    :opt_found => lambda {Log4r::Logger['dvdprofiler2xbmc'].info{"Dvdprofiler2xbmc #{Dvdprofiler2xbmc::VERSION}"}}, 
			    :opt_description => "This version of dvdprofiler2xbmc")
#       options << Option.new(:flag, :names => %w(--pretend -p))
      options << Option.new(:flag, :names => %w(--no_imdb_query -n))
      options << Option.new(:flag, :names => %w(--quiet -q))
      options << Option.new(:flag, :names => %w(--debug -d))
      options
    end
    
    # Reinitialize the logger using the loaded config.
    # logger:: logger for any user messages
    # config:: is the application's config hash.
    def self.reinitialize_logger(logger, quiet, debug)
      # switch the logger to the one specified in the config files
      unless AppConfig[:logfile].nil?
	logfile_outputter = Log4r::RollingFileOutputter.new(:logfile, :filename => AppConfig[:logfile], :maxsize => 1000000 )
	logger.add logfile_outputter
	logfile_outputter.level = Log4r::INFO
	Log4r::Outputter[:logfile].formatter = Log4r::PatternFormatter.new(:pattern => "[%l] %d :: %M")
	unless AppConfig[:logfile_level].nil?
	  level_map = {'DEBUG' => Log4r::DEBUG, 'INFO' => Log4r::INFO, 'WARN' => Log4r::WARN}
	  logfile_outputter.level = level_map[AppConfig[:logfile_level]] || Log4r::INFO
	end
      end
      Log4r::Outputter[:console].level = Log4r::INFO
      Log4r::Outputter[:console].level = Log4r::WARN if quiet
      Log4r::Outputter[:console].level = Log4r::DEBUG if debug
      # logger.trace = true
      AppConfig[:logger] = logger
    end
  end
end
  
    