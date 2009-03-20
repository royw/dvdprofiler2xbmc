# == Synopsis
# Media encapsulates information about a single media file
class Media
  attr_reader :media_path, :nfo_files, :image_files, :year, :media_subdirs
  attr_accessor :isbn

  DISC_NUMBER_REGEX = /\.(cd|part|disk|disc)\d+/i

  def initialize(directory, media_file)
    @media_subdirs = File.dirname(media_file)
    @media_path = File.expand_path(File.join(directory, media_file))
    Dir.chdir(File.dirname(@media_path))
    @nfo_files = Dir.glob("*.{#{AppConfig[:nfo_extensions].join(',')}}")
    @image_files = Dir.glob("*.{#{AppConfig[:media_extensions].join(',')}}")
    @year = $1 if File.basename(@media_path) =~ /\s\-\s(\d{4})/
  end

  # return the media's title extracted from the filename and cleaned up
  def title
    if @title.nil?
      # ditch extensions including disc number (ex, a.part2.b => a, a.cd1.b => a)
      @title = File.basename(@media_path, ".*").gsub(DISC_NUMBER_REGEX, '')
      @title.gsub!(/\s\-\s\d{4}/, '')  # remove year
      @title.gsub!(/\s\-\s0/, '')      # remove "- 0", i.e., bad year
      @title.gsub!(/\(\d{4}\)/, '')    # remove (year)
      @title.gsub!(/\[.+\]/, '')       # remove square brackets
      @title.gsub!(/\s\s+/, ' ')       # remove multiple whitespace
      @title = @title.strip            # remove leading and trailing whitespace
    end
    @title
  end

  def path_to(type)
    # ditch all extensions (ex, a.b => a, a.cd1.b => a)
    new_path = File.basename(@media_path, ".*").gsub(DISC_NUMBER_REGEX, '')
    unless (type == :base) || AppConfig[type].nil?
      new_path += '.' + AppConfig[type]
    end
    File.join(File.dirname(@media_path), new_path)
  end

  # return the media's title but with the (year) appended
  def title_with_year
    name = title
    name = "#{name} (#{@year})" unless @year.nil?
    name
  end

  def to_s
    buf = []
    buf << @media_path
    buf << '-'
    buf << title_with_year
    buf.join(' ')
  end
end
