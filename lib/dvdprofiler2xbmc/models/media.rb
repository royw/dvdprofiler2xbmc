# == Synopsis
# Media encapsulates information about a single media file
class Media
  attr_reader :media_path, :image_files, :year, :media_subdirs, :title, :title_with_year

  DISC_NUMBER_REGEX = /\.(cd|part|disk|disc)\d+/i

  def initialize(directory, media_file)
    @media_subdirs = File.dirname(media_file)
    @media_path = File.expand_path(File.join(directory, media_file))
    Dir.chdir(File.dirname(@media_path))
    @nfo_files = Dir.glob("*.{#{AppConfig[:nfo_extensions].join(',')}}")
    @image_files = Dir.glob("*.{#{AppConfig[:thumbnail_extension]}}")
    @year = $1 if File.basename(@media_path) =~ /\s\-\s(\d{4})/
    @title = find_title(@media_path)
    @title_with_year = find_title_with_year(@title, @year)

    @nfo = NfoController.new(self)
    @loaded = false
  end

  # load existing meta-data
  def load
    @nfo.load
    @loaded = true
  end

  # update the meta-data and thumbnails
  def update
    load unless @loaded
    @nfo.update
    @nfo.save
    update_thumbnail
  end

  # return the ISBN or nil
  def isbn
    @nfo.isbn
  end

  # return the IMDB ID or nil
  def imdb_id
    @nfo.imdb_id
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

  # update the movie's thumbnail (.tbn) image
  def update_thumbnail
    if @nfo.isbn.blank?
      unless @nfo.imdb_id.blank?
        if @image_files.empty?
          fetch_imdb_thumbnail(@nfo.imdb_id)
        end
      end
    else
      copy_thumbnail(@nfo.isbn)
    end
  end

  # fetch the thumbnail from IMDB and save as path_to('tbn')
  def fetch_imdb_thumbnail(imdb_id)
    imdb_movie = ImdbMovie.new(imdb_id.gsub(/^tt/, ''))
    source_uri = imdb_movie.poster.image
    dest_image_filespec = path_to(:thumbnail_extension)
    puts "fetch_imdb_thumbnail(#{imdb_id}) => #{source_uri}"
    begin
      File.open(dest_image_filespec, "wb") {|f| f.write(open(source_uri).read)}
    rescue Exception => e
      AppConfig[:logger].error { "Error downloading image from \"#{source_uri}\" to \"#{dest_image_filespec}\" - #{e.to_s}" }
    end
  end

  # copy images from .../isbn.jpg to .../basename.jpg
  def copy_thumbnail(isbn)
    src_image_filespec = File.join(AppConfig[:images_dir], "#{isbn}f.jpg")
    if File.exist?(src_image_filespec)
      dest_image_filespec = path_to(:thumbnail_extension)
      do_copy = true
      if File.exist?(dest_image_filespec)
        if File.mtime(src_image_filespec) <= File.mtime(dest_image_filespec)
          do_copy = false
        end
      end
      begin
        File.copy(src_image_filespec, dest_image_filespec) if do_copy
      rescue Exception => e
        AppConfig[:logger].error {e.to_s}
      end
    end
  end

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