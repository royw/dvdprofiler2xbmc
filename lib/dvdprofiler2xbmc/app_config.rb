# == Synopsis
# This module encapsulates the application's config hash by adding
# default, load, and save methods.  Also behaves as a global hash,
# meaning you can access it from anywhere in your code like:
#   AppConfig[:images_dir]
# or
#   AppConfig['images_dir']
# Note this is because the implementation is a Mash instead of
# a Hash and does cause a limitation where the key must be either
# a symbol or a string.
module AppConfig
  @config = Mash.new
  @yaml_filespec = File.join(ENV['HOME'], '.dvdprofiler2xbmcrc')
  
  def self.[](k)
    @config[k]
  end
  
  def self.[]=(k,v)
    @config[k] = v
  end
  
  def self.save
    begin
      File.delete(@yaml_filespec) if File.exist?(@yaml_filespec)
      AppConfig[:logger].info { "saving: #{@yaml_filespec}" }
      File.open(@yaml_filespec, "w") do |f|
	YAML.dump(@config, f)
      end
    rescue Exception => e
      AppConfig[:logger].error { "Error saving config file \"#{@yaml_filespec} - " + e.to_s + "\n" + e.backtrace.join("\n")}
    end
  end
  
  def self.load
    begin
      if File.exist?(@yaml_filespec)
	@config.merge YAML.load_file(@yaml_filespec)
      end
    rescue Exception => e
      AppConfig[:logger].error { "Error loading config file \"#{@yaml_filespec} - " + e.to_s }
    end
  end
  
  def self.default
    # Note, all paths and extensions are case sensitive 

    # Array of paths to scan for media
    # Note, directories underneath these will be added as genres to
    # each .nfo file.  For example:
    # /media/royw-gentoo/public/data/movies/Action/Bond/Goldeneye.m4v
    # will add 'Action' and 'Bond' genres to Goldeneye.nfo
    # Also note, that duplicate genres will be collapsed into single
    # genres in the .nfo file.
    @config.directories = [
	'/media/dad-kubuntu/public/data/videos_iso',
	'/media/dcerouter/public/data/videos_iso',
	'/media/royw-gentoo/public/data/videos_iso',
	'/media/royw-gentoo/public/data/movies'
      ]

    # Typical locations are:
    # @config.collection_filespec = File.join(ENV['HOME'], 'DVD Profiler/Databases/Exports/Collection.xml')
    # @config.images_dir = File.join(ENV['HOME'], 'DVD Profiler/Databases/Default/Images')
    #
    # My locations are:
    @config.collection_filespec = '/home/royw/DVD Profiler/Shared/Collection.xml'
    @config.images_dir = '/home/royw/DVD Profiler/Shared/Images'

    # You will probably need to edit the MEDIA_EXTENSIONS to specify
    # the containers used in your library
    @config.media_extensions = [ 'iso', 'm4v' ]

    # You probably will not need to change these
    # Source file extensions.
    @config.image_extensions    = [ 'jpg', 'jpeg', 'png', 'gif' ]
    @config.nfo_extensions      = [ 'nfo' ]
    # Destination file extensions
    @config.thumbnail_extension  = 'tbn'
    @config.nfo_extension        = 'nfo'
    @config.nfo_backup_extension = 'nfo~'

    # map some genre names
    @config.genre_maps = {
	'SciFi'           => 'Science Fiction',
	'Science-Fiction' => 'Science Fiction',
	'Anime'           => 'Animation',
	'Musical'         => 'Musicals'
      }

    @config.file_permissions = 0664
    @config.dir_permissions = 0777
    @config.imdb_query = true
  end
end
