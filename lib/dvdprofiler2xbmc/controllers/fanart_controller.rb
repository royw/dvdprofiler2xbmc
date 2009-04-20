# == Synopsis
# Media encapsulates information about a single media file
#
# Usage:
#  controller = FanartController.new(media)
#  controller.update
# or
#  FanartController.update(media)
class FanartController

  # == Synopsis
  # class access method
  def self.update(media)
    FanartController.new(media).update
  end

  # == Synopsis
  # media => Media instance
  def initialize(media)
    @media = media
  end

  # == Synopsis
  # update the meta-data and thumbnails
  def update
    result = true
    unless @media.imdb_id.blank?
      if @media.fanart_files.empty?
        fetch_fanart(@media.imdb_id)
        link_fanart(@media.path_to(:fanart))
      end
    end
    result
  end

  protected

  # == Synopsis
  # link the largest fanart to moviename-fanart.jpg
  def link_fanart(dest_filespec)
    %w(original mid thumb).each do |size|
      files = Dir.glob("#{dest_filespec}.#{size}.*")
      unless files.blank?
        filespec = files.sort.first
        extension = File.extname(filespec)
        link_filespec = dest_filespec + extension
        unless File.exist?(link_filespec)
          File.link(filespec, link_filespec)
        end
        break
      end
    end
  end

  # == Synopsis
  # fetch all of the fanart for the movie
  # save to files using format: moviename-fanart.size.N.jpg
  # where size is the fanart size ['original', 'mid', 'thumb']
  # and N is a sequential integer starting at 0
  def fetch_fanart(imdb_id)
    indexes = {}
    profile = TmdbProfile.new(imdb_id, TMDB_API_KEY, @media.path_to(:tmdb_xml), AppConfig[:logger])
    image = profile.image
    unless image.nil?
      image.fanart_sizes.each do |size|
        dest_filespec = get_destination_filespec(@media.media_path, size, indexes)
        image.fanart(size, dest_filespec)
      end
    end
  end

  # == Synopsis
  # generate a filespec using format: moviename-fanart.size.N
  # where size is the fanart size ['original', 'mid', 'thumb']
  # and N is a sequential integer starting at 0
  # Note, the calling routine should add the appropriate media extenstion like ".jpg"
  def get_destination_filespec(media_path, size, indexes)
    filespec = nil
    unless size.blank?
      indexes[size] ||= -1
      indexes[size] += 1
      extension = ".#{size}.#{indexes[size]}"
      filespec = DvdProfiler2Xbmc.generate_filespec(media_path, :fanart, :extension => extension)
    end
    filespec
  end

end
