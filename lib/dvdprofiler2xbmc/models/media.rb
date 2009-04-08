# == Synopsis
# Media encapsulates information about a single media file
class Media
  attr_reader :media_path, :image_files, :fanart_files, :year, :media_subdirs, :title, :title_with_year
  attr_accessor :isbn, :imdb_id

  DISC_NUMBER_REGEX = /\.(cd|part|disk|disc)\d+/i

  def initialize(directory, media_file)
    @media_subdirs = File.dirname(media_file)
    @media_path = File.expand_path(File.join(directory, media_file))

    cwd = File.expand_path(Dir.getwd)
    Dir.chdir(File.dirname(@media_path))
    @nfo_files = Dir.glob("*.{#{AppConfig[:nfo_extensions].join(',')}}")
    @image_files = Dir.glob("*.{#{AppConfig[:thumbnail_extension]}}")
    @fanart_files = Dir.glob("*fanart*}")
    Dir.chdir(cwd)

    @year = $1 if File.basename(@media_path) =~ /\s\-\s(\d{4})/
    @title = find_title(@media_path)
    @title_with_year = find_title_with_year(@title, @year)
  end

#   # return the ISBN or nil
#   def isbn
#     @nfo_controller.isbn
#   end
#
#   # return the IMDB ID or nil
#   def imdb_id
#     @nfo_controller.imdb_id
#   end

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
    new_path = File.basename(@media_path, ".*").gsub(DISC_NUMBER_REGEX, '')
    unless (type == :base) || AppConfig[type].nil?
      new_path += '.' + AppConfig[type]
    end
    File.join(File.dirname(@media_path), new_path)
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
    # ditch extensions including disc number (ex, a.part2.b => a, a.cd1.b => a)
    title = File.basename(media_path, ".*").gsub(DISC_NUMBER_REGEX, '')
    title.gsub!(/\s\-\s\d{4}/, '')  # remove year
    title.gsub!(/\s\-\s0/, '')      # remove "- 0", i.e., bad year
    title.gsub!(/\(\d{4}\)/, '')    # remove (year)
    title.gsub!(/\[.+\]/, '')       # remove square brackets
    title.gsub!(/\s\s+/, ' ')       # remove multiple whitespace
    title.strip                     # remove leading and trailing whitespace
  end

  # return the media's title but with the (year) appended
  def find_title_with_year(title, year)
    name = title
    name = "#{name} (#{year})" unless year.nil?
    name
  end

end
