require File.join(File.dirname(__FILE__), 'config_editor')
require 'commandline/optionparser'
# include CommandLine

# Command Line interface for the Dvdprofiler2Xbmc application.
# All application output is via AppConfig[:logger] so we have
# to set up the logger here.
# Also handle the command line options.
# Finally creates an instance of Dvdprofiler2Xbmc and executes
# it.

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

      begin
        # trap ^C interrupts and let the app instance cleanly exit any long loops
        Signal.trap("INT") {DvdProfiler2Xbmc.interrupt}

        logger = setup_logger

        # parse the command line
        options = setup_parser()
        od = options.parse(arguments)

        setup_app_config(od, logger)

        logger.info(AppConfig.to_s) if  od["--show_config"]

        if od["--edit_config"]
          editor = ConfigEditor.new
          editor.execute
        end

        skip_execution = false
        %w(--help --version --show_config --edit_config).each {|flag| skip_execution = true if od[flag]}
        unless skip_execution
          # create and execute class instance here
          app = DvdProfiler2Xbmc.instance
          app.execute
          app.report.each {|line| AppConfig[:logger].info line}
        end
      rescue Exception => eMsg
        logger.error {eMsg.to_s}
        logger.error {options.to_s}
        logger.error {eMsg.backtrace.join("\n")}
        exit_code = ExitCode::CRITICAL
      end
      exit_code
    end

    def self.setup_app_config(od, logger)
      # load config values
      AppConfig.default

      # the first reinitialize_logger adds the command line logging options to the default config
      # then we load the config files
      # then we run reinitialize_logger again to modify the logger for any logging options from the config files

      reinitialize_logger(logger, od["--quiet"], od["--debug"])
      AppConfig.load
      AppConfig.save
      AppConfig[:logfile] = od['--output'] if od['--output']
      AppConfig[:logfile_level] = od['--output_level'] if od['--output_level']
      reinitialize_logger(logger, od["--quiet"], od["--debug"])

      AppConfig[:do_update] = !od["--reports"]
      AppConfig[:force_nfo_replacement] = od["--force_nfo_replacement"]

      AppConfig[:logger].info { "logfile => #{AppConfig[:logfile].inspect}" } unless AppConfig[:logfile].nil?
      AppConfig[:logger].info { "logfile_level => #{AppConfig[:logfile_level].inspect}" } unless AppConfig[:logfile_level].nil?
    end

    # Setup the command line option parser
    # Returns:: OptionParser instances
    def self.setup_parser()
      options = CommandLine::OptionParser.new()

      # flag options
      [
        {
          :names           => %w(--version -v),
          :opt_found       => lambda {Log4r::Logger['dvdprofiler2xbmc'].info{"Dvdprofiler2xbmc #{Dvdprofiler2xbmc::VERSION}"}},
          :opt_description => "This version of dvdprofiler2xbmc"
        },
        {
          :names           => %w(--help -h),
          :opt_found       => lambda {Log4r::Logger['dvdprofiler2xbmc'].info{options.to_s}},
          :opt_description => "This usage information"
        },
        {
          :names           => %w(--show_config -s),
          :opt_description => "This is the current configuration information"
        },
        {
          :names           => %w(--edit_config -e),
          :opt_description => "Edit the current configuration information"
        },
        {
          :names           => %w(--quiet -q),
          :opt_description => 'Display error messages only'
        },
        {
          :names           => %w(--debug -d),
          :opt_description => 'Display debug messages'
        },
        {
          :names           => %w(--force_nfo_replacement -f),
          :opt_description => 'Delete old .nfo files and generate new ones'
        },
        {
          :names           => %w(--reports -r),
          :opt_description => 'Display reports only.  Do not do any updates.'
        }
      ].each { |opt| options << CommandLine::Option.new(:flag, opt) }

      # non-flag options
      [
        {
          :names           => %w(--output -o),
          :argument_arity  => [1,1],
          :arg_description => 'logfile',
          :opt_description => 'Write log messages to file. Default = no log file',
          :opt_found       => CommandLine::OptionParser::GET_ARGS
        },
        {
          :names           => %w(--output_level -l),
          :argument_arity  => [1,1],
          :arg_description => 'level',
          :opt_description => 'Output logging level: DEBUG, INFO, WARN, ERROR. Default = INFO',
          :opt_found       => CommandLine::OptionParser::GET_ARGS
        }
      ].each { |opt| options << CommandLine::Option.new(opt) }

      options
    end

    # Initial setup of logger
    def self.setup_logger
      logger = Log4r::Logger.new('dvdprofiler2xbmc')
      logger.outputters = Log4r::StdoutOutputter.new(:console)
      Log4r::Outputter[:console].formatter  = Log4r::PatternFormatter.new(:pattern => "%m")
      logger.level = Log4r::DEBUG
      logger
    end

    # Reinitialize the logger using the loaded config.
    # logger:: logger for any user messages
    # config:: is the application's config hash.
    def self.reinitialize_logger(logger, quiet, debug)
      # switch the logger to the one specified in the config files
      unless AppConfig[:logfile].blank?
        logfile_outputter = Log4r::RollingFileOutputter.new(:logfile, :filename => AppConfig[:logfile], :maxsize => 1000000 )
        logger.add logfile_outputter
        AppConfig[:logfile_level] ||= 'INFO'
        Log4r::Outputter[:logfile].formatter = Log4r::PatternFormatter.new(:pattern => "[%l] %d :: %M")
        level_map = {'DEBUG' => Log4r::DEBUG, 'INFO' => Log4r::INFO, 'WARN' => Log4r::WARN}
        logfile_outputter.level = level_map[AppConfig[:logfile_level].upcase] || Log4r::INFO
      end
      Log4r::Outputter[:console].level = Log4r::INFO
      Log4r::Outputter[:console].level = Log4r::WARN if quiet
      Log4r::Outputter[:console].level = Log4r::DEBUG if debug
      Log4r::Outputter[:console].formatter = Log4r::PatternFormatter.new(:pattern => "%m")
                                                                                       # logger.trace = true
      AppConfig[:logger] = logger
    end
  end
end

