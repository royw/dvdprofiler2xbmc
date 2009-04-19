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

  # @config, @help, @initial, @data_type, @validate, and @validate_item
  # are mashes that share the same keys.  For example @help.foo would be
  # the help text for @config.foo

  # == Synopsis
  # the current config values
  @config    = Mash.new

  # == Synopsis
  # help about the config item
  @help      = Mash.new

  # == Synopsis
  # initial (default) config values
  @initial   = Mash.new

  # == Synopsis
  # data type constants used in the editor
  @data_type = Mash.new

  # == Synopsis
  # validate the config item
  @validate  = Mash.new

  # == Synopsis
  # validate an entry for a config item, note usually need to allow
  # empty string for either array entry termination or to accept
  # a default value
  @validate_item = Mash.new

  # == Synopsis
  # the @navigation array contains hashes where each hash is a "page"
  # that contains an array of @config keys.  This provides a natural
  # organization for UIs.
  @navigation = []

  # make class variables readable
  class << self
    attr_reader :help, :initial, :navigation, :config, :data_type, :validate, :validate_item
  end

  # the user's config file
  @yaml_filespec = File.join(ENV['HOME'], '.dvdprofiler2xbmcrc')

  # == Synopsis
  # shortcut accessor for @config items
  def self.[](k)
    @config[k]
  end

  # == Synopsis
  # shortcut accessor for @config items
  def self.[]=(k,v)
    @config[k] = v
  end

  # == Synopsis
  # does the config file exist?
  def self.exist?
    File.exist?(@yaml_filespec)
  end

  # == Synopsis
  # load the config file, overwriting current values
  def self.load
    begin
      if File.exist?(@yaml_filespec)
        cfg = YAML.load_file(@yaml_filespec)
        cfg.delete('logger')
        if cfg.version != @config.version
          AppConfig[:logger].info {"config file (#{@yaml_filespec}) version mismatch"}
          AppConfig[:logger].info {"file version => #{cfg.version}"}
          AppConfig[:logger].info {"config version => #{@config.version}"}
          # remove from @config any keys that are not in cfg
          file_keys = cfg.keys.sort
          current_keys = @config.keys.sort
          intersection_keys = file_keys & current_keys
          obsolete_keys = file_keys - intersection_keys
          obsolete_keys.each do |key|
            AppConfig[:logger].info { "removing obsolete key #{key}"}
            cfg.delete(key)
          end
          cfg.delete('version')
        end
        @config.merge! cfg
      end
    rescue Exception => e
      AppConfig[:logger].error { "Error loading config file \"#{@yaml_filespec} - " + e.to_s + "\n" + e.backtrace.join("\n") }
    end
  end

  # == Synopsis
  # save the config file
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

  # == Synopsis
  # generate a string for displaying the current config
  def self.to_s
    buf = []
    @navigation.each do |page|
      page.each do |heading, keys|
        buf << heading
        buf << ''
        keys.each do |key|
          buf << key
          buf << @help[key].split("\n").collect{|line| "  " + line}.join("\n") unless @help[key].blank?
          buf << "Initial:"
          buf << @initial[key].pretty_inspect.collect{|line| "  " + line.rstrip}
          buf << "Current:"
          buf << @config[key].pretty_inspect.collect{|line| "  " + line.rstrip}
          buf << ''
        end
        buf << ''
      end
    end
    buf.join("\n")
  end

  # == Synopsis
  # is the current config valid?
  def self.valid?
    valid = true
    @validate.each do |field, value|
      unless @validate[field].call(@config[field])
        valid = false
      end
    end
    valid
  end

  # == Synopsis
  # set the config to the default values
  def self.default
    # Note, all paths and extensions are case sensitive

    # this is the version of the rc file and is used to trigger
    # removal of no longer existing keys
    @config.version = '0.1.0'

    @config.color_enabled = true

    @navigation = [
        {'Application Options' => %w(color_enabled)},
        {'Setup Paths' => %w(directories subdirs_as_genres collection_filespec images_dir)},
        {'Setup Permissions'=> %w(file_permissions dir_permissions)},
        {'Setup Genre Mapping' => %w(genre_maps)},
        {'File Naming' => %w(media_extensions image_extensions naming)},
        {'Parsing' => %w(part_regex media_parsers)}
      ]

    @help.directories = [
        'Array of paths to scan for media.  Replace with your paths.'
      ].join("\n")
    @initial.directories = []
    # My directories are:
    @config.directories = [
#         '/media/dad-kubuntu/public/data/videos_iso',
#         '/media/dcerouter/public/data/videos_iso',
#         '/media/royw-gentoo/public/data/videos_iso',
#         '/media/royw-gentoo/public/data/movies'
      ]
    @data_type.directories = :ARRAY_OF_PATHSPECS
    @validate.directories = lambda do |directories|
      valid = false
      unless directories.empty?
        valid = true
        directories.each do |dir|
          unless File.exist?(dir) && File.directory?(dir)
            valid = false
          end
        end
      end
      valid
    end
    @validate_item.directories = lambda do |dir|
      dir.empty? || (File.exist?(dir) && File.directory?(dir))
    end

    @help.subdirs_as_genres = [
        'Directories underneath these will be added as genres to each .nfo file.',
        'For example:',
        '  /media/movies/Action/Bond/Goldeneye.m4v',
        'will add "Action" and "Bond" genres to Goldeneye.nfo',
        'Also note, that duplicate genres will be collapsed into single genres in the .nfo file.'
      ].join("\n")
    @initial.subdirs_as_genres = true
    @config.subdirs_as_genres = @initial.subdirs_as_genres
    @data_type.subdirs_as_genres = :BOOLEAN

    # Typical locations are:
    # @config.collection_filespec = File.join(ENV['HOME'], 'DVD Profiler/Databases/Exports/Collection.xml')
    # @config.images_dir = File.join(ENV['HOME'], 'DVD Profiler/Databases/Default/Images')
    #
    @help.collection_filespec = [
        'The location of DVD Profiler\'s exported Collection.xml'
      ].join("\n")
    @initial.collection_filespec = '~/DVD Profiler/Databases/Exports/Collection.xml'
    # My location is:
    @config.collection_filespec = @initial.collection_filespec
#     @config.collection_filespec = '/home/royw/DVD Profiler/Shared/Collection.xml'
    @data_type.collection_filespec = :FILESPEC
    @validate.collection_filespec = lambda do |filespec|
      File.exist?(filespec) && File.file?(filespec)
    end
    @validate_item.collection_filespec = lambda do |filespec|
      filespec.empty? || (File.exist?(filespec) && File.file?(filespec))
    end

    @help.images_dir = [
        'The location of DVD Profiler\'s cover scan images.'
      ].join("\n")
    @initial.images_dir = '~/DVD Profiler/Databases/Exports/Images'
    # My location is:
    @config.images_dir = @initial.images_dir
#     @config.images_dir = '/home/royw/DVD Profiler/Shared/Images'
    @data_type.images_dir = :PATHSPEC
    @validate.images_dir = lambda do |directory|
      File.exist?(directory) && File.directory?(directory)
    end
    @validate_item.images_dir = lambda do |directory|
      directory.empty? || (File.exist?(directory) && File.directory?(directory))
    end

    # You will probably need to edit the MEDIA_EXTENSIONS to specify
    # the containers used in your library
    @help.media_extensions = [
        'The supported file extensions for movie media.',
        'You probably will not need to edit this list.'
      ].join("\n")
    @initial.media_extensions = %w(iso m4v mp4 mpeg wmv asf flv mkv mov aac nut ogg ogm ram rm rv ra rmvb 3gp vivo pva nuv nsv nsa fli flc)
    @config.media_extensions = @initial.media_extensions
    @data_type.media_extensions = :ARRAY_OF_STRINGS
    @validate.media_extensions = lambda do |extensions|
      !extensions.collect{|ext| ext.blank? ? nil : ext}.compact.empty?
    end
    @validate_item.media_extensions = lambda do |extension|
      true
    end

    # You probably will not need to change these
    # Source file extensions.
    @help.image_extensions = [
        'The file extensions for image files such as cover art, fan art, and thumbnails.',
        'You probably will not need to edit this list.'
      ].join("\n")
    @initial.image_extensions = %w(jpg jpeg png gif bmp tbn)
    @config.image_extensions  = @initial.image_extensions
    @data_type.image_extensions = :ARRAY_OF_STRINGS
    @validate.image_extensions = lambda do |extensions|
      !extensions.collect{|ext| ext.blank? ? nil : ext}.compact.empty?
    end
    @validate_item.media_extensions = lambda do |extension|
      true
    end

    # map some genre names
    @help.genre_maps = [
        'Change the name of genres.',
        'For example, "SciFi" can be mapped to "Science Fiction"'
      ].join("\n")
    @initial.genre_maps = {
      'SciFi'           => 'Science Fiction',
      'Sci-Fi'          => 'Science Fiction',
      'Science-Fiction' => 'Science Fiction',
      'Anime'           => 'Animation',
      'Musical'         => 'Musicals',
      'Music'           => 'Musicals',
      'War Film'        => 'War',
      'Western'         => 'Westerns'
    }
    @config.genre_maps = @initial.genre_maps
    @data_type.genre_maps = :HASH_STRING_KEYS_STRING_VALUES

    @help.file_permissions = [
        'Set the file permissions of all files in the scanned directories to this value.',
        'This is useful to maintain consistancy of file permissions'
      ].join("\n")
    @initial.file_permissions = 0664.to_s(8)
    @config.file_permissions = @initial.file_permissions
    @data_type.file_permissions = :PERMISSIONS
    @validate.file_permissions = lambda do |permissions|
      (permissions.to_i(8) >= 0) && (permissions.to_i(8) <= 07777)
    end
    @validate_item.file_permissions = lambda do |permissions|
      permissions.empty? || ((permissions.to_i(8) >= 0) && (permissions.to_i(8) <= 07777))
    end

    @help.dir_permissions = [
        'Set the directory permissions of all sub-directories in the scanned directories to this value.',
        'This is useful to maintain consistancy of directory permissions'
      ].join("\n")
    @initial.dir_permissions = 0777.to_s(8)
    @config.dir_permissions = @initial.dir_permissions
    @data_type.dir_permissions = :PERMISSIONS
    @validate.dir_permissions = lambda do |permissions|
      permissions.empty? || ((permissions.to_i(8) >= 0) && (permissions.to_i(8) <= 07777))
    end

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
        :isbn             => 'isbn',
        :imdb             => 'imdb',
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
        '  %p => the part substring from the media file (ex: \'cd1\', \'disc3\')',
        '  %r => video resolution',
        '  %y => year'
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
    #  *.ptN.*
    #  *.diskN.*
    #  *.discN.*
    @help.part_regex = [
        'The regular expression for parsing the part sub-string from the media file.',
        'For example to find "cd2" in "movie.cd2.avi"'
      ].join("\n")
    @initial.part_regex = /\.(cd|pt|disk|disc)\d+/i
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
        ':extension will be assigned the second match ([^.]+).',
        'Valid tokens are:  :title, :year, :resolution, :part, :extension'
      ].join("\n")
    @initial.media_parsers = [
      # "movie title - yyyy[res].partN.ext"
      {:regex => /^\s*(.*\S)\s*\-\s*(\d{4})\s*\[(\S*)\]\s*\.(cd\d+|pt\d+|disk\d+|disc\d+)\.([^.]+)\s*$/,
      :tokens => [:title, :year, :resolution, :part, :extension]
      },
      # "movie title (yyyy)[res].partN.ext"
      {:regex => /^\s*(.*\S)\s*\(\s*(\d{4})\s*\)\s*\[(\S*)\]\s*\.(cd\d+|pt\d+|disk\d+|disc\d+)\.([^.]+)\s*$/,
      :tokens => [:title, :year, :resolution, :part, :extension]
      },
      # "movie title[res].partN.ext"
      {:regex => /^\s*(.*\S)\s*\[(\S*)\]\s*\.(cd\d+|pt\d+|disk\d+|disc\d+)\.([^.]+)\s*$/,
      :tokens => [:title, :resolution, :part, :extension]
      },
      # "movie title - yyyy[res].ext"
      {:regex => /^\s*(.*\S)\s*\-\s*(\d{4})\s*\[(\S*)\]\s*\.([^.]+)\s*$/,
      :tokens => [:title, :year, :resolution, :extension]
      },
      # "movie title (yyyy)[res].ext"
      {:regex => /^\s*(.*\S)\s*\(\s*(\d{4})\s*\)\s*\[(\S*)\]\s*\.([^.]+)\s*$/,
      :tokens => [:title, :year, :resolution, :extension]
      },
      # "movie title[res].ext"
      {:regex => /^\s*(.*\S)\s*\[(\S*)\]\s*\.([^.]+)\s*$/,
      :tokens => [:title, :resolution, :extension]
      },
      # "movie title - yyyy.partN.ext"
      {:regex => /^\s*(.*\S)\s*\-\s*(\d{4})\s*\.(cd\d+|pt\d+|disk\d+|disc\d+)\.([^.]+)\s*$/,
      :tokens => [:title, :year, :part, :extension]
      },
      # "movie title (yyyy).partN.ext"
      {:regex => /^\s*(.*\S)\s*\(\s*(\d{4})\s*\)\s*\.(cd\d+|pt\d+|disk\d+|disc\d+)\.([^.]+)\s*$/,
      :tokens => [:title, :year, :part, :extension]
      },
      # "movie title.partN.ext"
      {:regex => /^\s*(.*\S)\s*\.(cd\d+|pt\d+|disk\d+|disc\d+)\.([^.]+)\s*$/,
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

    @help.do_update = [
        'Perform update.'
      ].join("\n")
    @initial.do_update = true
    @config.do_update = @initial.do_update
  end

  private
  def initialize
    AppConfig[:logger].error {"Should never be instantiated"}
  end
end
