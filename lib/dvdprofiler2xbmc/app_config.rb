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
  @help = Mash.new
  @initial = Mash.new

  @yaml_filespec = File.join(ENV['HOME'], '.dvdprofiler2xbmcrc')

  def self.[](k)
    @config[k]
  end

  def self.[]=(k,v)
    @config[k] = v
  end

  def self.save
    begin
      unless @config.blank?
        File.delete(@yaml_filespec) if File.exist?(@yaml_filespec)
        AppConfig[:logger].info { "saving: #{@yaml_filespec}" }
        File.open(@yaml_filespec, "w") do |f|
          cfg = @config
          cfg.delete('logger')
          YAML.dump(cfg, f)
        end
      end
    rescue Exception => e
      AppConfig[:logger].error { "Error saving config file \"#{@yaml_filespec} - " + e.to_s + "\n" + e.backtrace.join("\n")}
    end
  end

  def self.load
    begin
      if File.exist?(@yaml_filespec)
        cfg = YAML.load_file(@yaml_filespec)
        cfg.delete('logger')
        @config.merge! cfg
      end
    rescue Exception => e
      AppConfig[:logger].error { "Error loading config file \"#{@yaml_filespec} - " + e.to_s }
    end
  end

  def self.default
    # Note, all paths and extensions are case sensitive

    @help.directories = [
        'Array of paths to scan for media.  Replace with your paths.'
      ].join("\n")
    @initial.directories = []
    # My directories are:
    @config.directories = [
        '/media/dad-kubuntu/public/data/videos_iso',
        '/media/dcerouter/public/data/videos_iso',
        '/media/royw-gentoo/public/data/videos_iso',
        '/media/royw-gentoo/public/data/movies'
      ]

    @help.subdirs_as_genres = [
        'Directories underneath these will be added as genres to each .nfo file.',
        'For example:',
        '  /media/royw-gentoo/public/data/movies/Action/Bond/Goldeneye.m4v',
        'will add "Action" and "Bond" genres to Goldeneye.nfo',
        'Also note, that duplicate genres will be collapsed into single genres in the .nfo file.'
      ].join("\n")
    @initial.subdirs_as_genres = true
    @config.subdirs_as_genres = @initial.subdirs_as_genres

    # Typical locations are:
    # @config.collection_filespec = File.join(ENV['HOME'], 'DVD Profiler/Databases/Exports/Collection.xml')
    # @config.images_dir = File.join(ENV['HOME'], 'DVD Profiler/Databases/Default/Images')
    #
    @help.collection_filespec = [
        'The location of DVD Profiler\'s exported Collection.xml'
      ].join("\n")
    @initial.collection_filespec = '~/DVD Profiler/Databases/Exports/Collection.xml'
    # My location is:
    @config.collection_filespec = '/home/royw/DVD Profiler/Shared/Collection.xml'

    @help.collection_filespec = [
        'The location of DVD Profiler\'s cover scan images.'
      ].join("\n")
    @initial.images_dir = '~/DVD Profiler/Databases/Exports/Images'
    # My location is:
    @config.images_dir = '/home/royw/DVD Profiler/Shared/Images'

    # You will probably need to edit the MEDIA_EXTENSIONS to specify
    # the containers used in your library
    @help.media_extensions = [
        'The supported file extensions for movie media.',
        'You probably will not need to edit this list.'
      ].join("\n")
    @initial.media_extensions = %w(iso m4v mp4 mpeg wmv asf flv mkv mov aac nut ogg ogm ram rm rv ra rmvb 3gp vivo pva nuv nsv nsa fli flc)
    @config.media_extensions = @initial.media_extensions

    # You probably will not need to change these
    # Source file extensions.
    @help.image_extensions = [
        'The file extensions for image files such as cover art, fan art, and thumbnails.',
        'You probably will not need to edit this list.'
      ].join("\n")
    @initial.image_extensions = %w(jpg jpeg png gif bmp tbn)
    @config.image_extensions  = @initial.image_extensions
    # Destination file extensions

    # This maps the file type to extension.
    # The one unusual case in the list is for :fanart where
    # the actually media extension will be appended to this
    # extension (see FanartController)
    @help.extensions = [
        'Internally used to map types to file extensions.',
        'You may change the values if you need different file extensions.',
        'Do not change the keys unless you really know what you are doing!'
      ].join("\n")
    @initial.extensions  = {
        :fanart           => '-fanart',
        :thumbnail        => 'tbn',
        :nfo              => 'nfo',
        :dvdprofiler_xml  => 'dvdprofiler.xml',
        :imdb_xml         => 'imdb.xml',
        :tmdb_xml         => 'tmdb.xml',
        :new              => 'new',
        :backup           => '~',
        :no_isbn          => 'no_isbn',
        :no_imdb_lookup   => 'no_imdb_lookup',
        :no_tmdb_lookup   => 'no_tmdb_lookup',
      }
    @config.extensions  = @initial.extensions

    # substitutions:
    #  %t  => movie title
    #  %e  => extension from @config.extensions
    #  %p  => part
    @help.naming = [
        'Defines the various formatting of generated file names.',
        'Do not change the naming keys (ex: :fanart, :thumbnail,...).',
        'The :part key/value defines the format for a multi-part media while :no_part defines the format for single part media.',
        'The substutions are:',
        '  %t => movie title',
        '  %e => appropriate file extension',
        '  %p => the part substring from the media file (ex: \'cd1\', \'disc3\')'
      ].join("\n")
    @initial.naming = {
        :fanart          => {:part => '%t%e',  :no_part => '%t%e'},
        :thumbnail       => {:part => '%t.%e', :no_part => '%t.%e'},
        :nfo             => {:part => '%t.%e', :no_part => '%t.%e'},
        :dvdprofiler_xml => {:part => '%t.%e', :no_part => '%t.%e'},
        :imdb_xml        => {:part => '%t.%e', :no_part => '%t.%e'},
        :tmdb_xml        => {:part => '%t.%e', :no_part => '%t.%e'}
      }
    @config.naming = @initial.naming

    # recognized multi-part tokens where N is an integer:
    #  *.cdN.*
    #  *.partN.*
    #  *.ptN.*
    #  *.diskN.*
    #  *.discN.*
    @help.part_regex = [
        'The regular expression for parsing the part sub-string from the media file.',
        'For example to find "cd2" in "movie.cd2.avi"'
      ].join("\n")
    @initial.part_regex = /\.(cd|part|pt|disk|disc)\d+/i
    @config.part_regex = @initial.part_regex

    # media filename parsers.
    # The :tokens array refers to the matches in the regex, ex:
    #  {:regex => /^\s*(.*\S)\s*\.([^.]+)\s*$/, :tokens => [:title, :extension]}
    # :title will be assigned the first match (.*\S) and
    # :extension will be assigned the second match ([^.]+)
    # See (Media.parse)
    @help.media_parsers = [
        'Media filename parsers.',
        'The :tokens array refers to the matches in the regex, ex:',
        '  {:regex => /^\s*(.*\S)\s*\.([^.]+)\s*$/, :tokens => [:title, :extension]}',
        ':title will be assigned the first match (.*\S) and',
        ':extension will be assigned the second match ([^.]+)'
      ].join("\n")
    @initial.media_parsers = [
      # "movie title - yyyy.partN.ext"
      {:regex => /^\s*(.*\S)\s*\-\s*(\d{4})\s*\.(cd\d+|part\d+|pt\d+|disk\d+|disc\d+)\.([^.]+)\s*$/,
       :tokens => [:title, :year, :part, :extension]
       },
      # "movie title (yyyy).partN.ext"
      {:regex => /^\s*(.*\S)\s*\(\s*(\d{4})\s*\)\s*\.(cd\d+|part\d+|pt\d+|disk\d+|disc\d+)\.([^.]+)\s*$/,
       :tokens => [:title, :year, :part, :extension]
       },
      # "movie title.partN.ext"
      {:regex => /^\s*(.*\S)\s*\.(cd\d+|part\d+|pt\d+|disk\d+|disc\d+)\.([^.]+)\s*$/,
       :tokens => [:title, :part, :extension]
       },
      # "movie title - yyyy.ext"
      {:regex => /^\s*(.*\S)\s*\-\s*(\d{4})\s*\.([^.]+)\s*$/,
       :tokens => [:title, :year, :extension]
       },
      # "movie title (yyyy).ext"
      {:regex => /^\s*(.*\S)\s*\(\s*(\d{4})\s*\)\s*\.([^.]+)\s*$/,
       :tokens => [:title, :year, :extension]
       },
      # "movie title.ext"
      {:regex => /^\s*(.*\S)\s*\.([^.]+)\s*$/,
       :tokens => [:title, :extension]
       }
    ]
    @config.media_parsers = @initial.media_parsers

    # map some genre names
    @help.genre_maps = [
        'Change the name of genres.',
        'For example, "SciFi" can be mapped to "Science Fiction"'
      ].join("\n")
    @initial.genre_maps = {
      'SciFi'           => 'Science Fiction',
      'Science-Fiction' => 'Science Fiction',
      'Anime'           => 'Animation',
      'Musical'         => 'Musicals',
      'Music'           => 'Musicals',
      'War Film'        => 'War'
    }
    @config.genre_maps = @initial.genre_maps

    @help.file_permissions = [
        'Set the file permissions of all files in the scanned directories to this value.',
        'This is useful to maintain consistancy of file permissions'
      ].join("\n")
    @initial.file_permissions = 0664
    @config.file_permissions = @initial.file_permissions

    @help.dir_permissions = [
        'Set the directory permissions of all sub-directories in the scanned directories to this value.',
        'This is useful to maintain consistancy of directory permissions'
      ].join("\n")
    @initial.dir_permissions = 0777
    @config.dir_permissions = @initial.dir_permissions

    @help.do_update = [
        'Perform update.'
      ].join("\n")
    @initial.do_update = true
    @config.do_update = @initial.do_update
  end
end
