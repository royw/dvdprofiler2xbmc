# == Synopsis
# Media encapsulates information about a single media file
class Media
  attr_reader :media_path, :image_files, :fanart_files, :media_subdirs, :title, :title_with_year, :part, :extension
  attr_accessor :isbn, :imdb_id, :resolution, :year

  def initialize(directory, media_file)
    @media_subdirs = File.dirname(media_file)
    @media_path = File.expand_path(File.join(directory, media_file))

    cwd = File.expand_path(Dir.getwd)
    Dir.chdir(File.dirname(@media_path))
    @nfo_files = Dir.glob("*.{#{AppConfig[:extensions][:nfo]}}")
    @image_files = Dir.glob("*.{#{AppConfig[:extensions][:thumbnail]}}")
    @fanart_files = Dir.glob("*#{AppConfig[:extensions][:fanart]}*}")
    Dir.chdir(cwd)

    components = Media.parse(@media_path)
    unless components.nil?
      @year = components[:year]
      @title = components[:title]
      @part = components[:part]
      @extension = components[:extension]
      @resolution = components[:resolution]
    end
    @title_with_year = find_title_with_year(@title, @year)
  end

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

  def to_s
    buf = []
    buf << @media_path
    buf << '-'
    buf << title_with_year
    buf.join(' ')
  end

  protected

  # return the media's title extracted from the filename and cleaned up
  def find_title(media_path)
    Media.parse(media_path)[:title] rescue nil
  end

  # return the media's title but with the (year) appended
  def find_title_with_year(title, year)
    name = title
    name = "#{name} (#{year})" unless year.nil?
    name
  end

end
