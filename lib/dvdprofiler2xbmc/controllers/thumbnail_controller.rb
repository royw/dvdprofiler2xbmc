# == Synopsis
# Media encapsulates information about a single media file
#
# Usage:
#  controller = ThumbnailController.new(media)
#  controller.update
# or
#  ThumbnailController.update(media)
class ThumbnailController

  def self.update(media)
    ThumbnailController.new(media).update
  end

  def initialize(media)
    @media = media
  end

  # update the movie's thumbnail (.tbn) image
  def update
    result = false
    if @media.isbn.blank?
      unless @media.imdb_id.blank?
        if @media.image_files.empty?
          fetch_imdb_thumbnail(@media.imdb_id)
          result = true
        end
      end
    else
      copy_thumbnail(@media.isbn)
      result = true
    end
    result
  end

  protected

  # fetch the thumbnail from IMDB and save as path_to('tbn')
  def fetch_imdb_thumbnail(imdb_id)
    imdb_movie = ImdbMovie.new(imdb_id.gsub(/^tt/, ''))
    source_uri = imdb_movie.poster.image
    dest_image_filespec = @media.path_to(:thumbnail)
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
      dest_image_filespec = @media.path_to(:thumbnail)
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

end
