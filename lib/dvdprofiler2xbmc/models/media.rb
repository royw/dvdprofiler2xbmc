# == Synopsis
# Media encapsulates information about a single media file
class Media

  # == Synopsis
  # filespec to the media file
  attr_reader :media_path

  # == Synopsis
  # Array of image filenames associated with the media
  attr_reader :image_files

  # == Synopsis
  # Array of fanart filenames associated with the media
  attr_reader :fanart_files

  # == Synopsis
  # The realative pathspec from the top level directory to the
  # directory that contains the media
  attr_reader :media_subdirs

  # == Synopsis
  # The media's title String
  attr_reader :title

  # == Synopsis
  # The media's title and year String ("title (year)")
  attr_reader :title_with_year

  # == Synopsis
  # nil or a String contain the media part (ex: cd1, disk2)
  attr_reader :part

  # == Synopsis
  # The file extension for the media
  attr_reader :extension

  # == Synopsis
  # The ISBN number in a String for the media
  attr_accessor :isbn

  # == Synopsis
  # The IMDB ID in a String for the media
  attr_accessor :imdb_id

  # == Synopsis
  # The video resolution as a String
  attr_accessor :resolution

  # == Synopsis
  # The media's production year
  attr_accessor :year

  # == Synopsis
  # directory  => String containing pathspec to the top level directory of the media
  # media_file => String containing relative pathspec from the top level
  #               directory of the media to the media file
  def initialize(directory, media_file)
    @media_subdirs = File.dirname(media_file)
    @media_path = File.expand_path(File.join(directory, media_file))

    Dir.chdir(File.dirname(@media_path)) do
      @nfo_files = Dir.glob("*.{#{AppConfig[:extensions][:nfo]}}")
      @image_files = Dir.glob("*.{#{AppConfig[:extensions][:thumbnail]}}")
      @fanart_files = Dir.glob("*#{AppConfig[:extensions][:fanart]}*}")
    end

    components = Media.parse(@media_path)
    unless components.nil?
      @year = components[:year]
      @year = (@year.to_i > 0 ? @year : nil) unless @year.blank?
      @title = components[:title]
      @part = components[:part]
      @extension = components[:extension]
      @resolution = components[:resolution]
    end
    @title_with_year = find_title_with_year(@title, @year)
  end

  # == Synopsis
  # return a path to a file file based on the media's filespec
  # but without any stacking parts and with the given extension
  # instead of the media's extension.
  # Example:
  #  media_path = '/a/b/c.m4v'
  #  path_to('nfo') => '/a/b/c.nfo'
  #  media_path = '/a/b/c.part1.m4v'
  #  path_to('nfo') => '/a/b/c.nfo'
  def path_to(type)
    # ditch all extensions (ex, a.b => a, a.cd1.b => a)
    DvdProfiler2Xbmc.generate_filespec(@media_path, type, :year => @year, :resolution => @resolution)
  end

  # == Synopsis
  # parse the given filespec into a hash the consists of the
  # found parts with keys:
  #  :title       required
  #  :year        optional
  #  :part        optional
  #  :extension   required
  def self.parse(filespec)
    result = nil
    filename = File.basename(filespec)
    AppConfig[:media_parsers].each do |parser|
      match_data = parser.regex.match(filename)
      unless match_data.nil?
        if((match_data.length - 1) == parser.tokens.length)
          index = 1
          result = {}
          parser.tokens.each do |token|
            result[token] = match_data[index]
            index += 1
          end
          break
        end
      end
    end
    result
  end

  # == Synopsis
  # return human readable string representation
  def to_s
    buf = []
    buf << @media_path
    buf << '-'
    buf << title_with_year
    buf.join(' ')
  end

  protected

  # == Synopsis
  # return the media's title extracted from the filename and cleaned up
  def find_title(media_path)
    Media.parse(media_path)[:title] rescue nil
  end

  # == Synopsis
  # return the media's title but with the (year) appended
  def find_title_with_year(title, year)
    name = title
    name = "#{name} (#{year})" unless year.blank?
    name
  end

end
