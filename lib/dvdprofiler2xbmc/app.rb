# == Synopsis
# Transfer media meta data from DvdProfiler to the format that XBMC needs it (.tbn and .nfo files)
#
# usage:
#  app = DvdProfiler2Xbmc.new
#  app.execute
#  app.report.each {|line| puts line}
class DvdProfiler2Xbmc
  include Singleton

  @interrupted = false

  # A trap("INT") in the Runner calls this to indicate that a ^C has been detected.
  # Note, once set, it is never cleared
  def self.interrupt
    AppConfig[:logger].error { "control-C detected, finishing current task" }
    @interrupted = true
  end

  # Long loops should poll this method to see if they should abort
  # Returns:: true if the application has trapped an "INT", false otherwise
  def self.interrupted?
    @interrupted
  end

  def initialize
    @media_files = nil
  end

  def execute
    @media_files = MediaFiles.new(AppConfig[:directories])

    collection_filepath = File.expand_path(AppConfig[:collection_filespec])
    collection = Collection.new(collection_filepath)

    @media_files.titles.each do |title, medias|
      break if DvdProfiler2Xbmc.interrupted?
      # the following lines are order dependent
      find_isbns(title, medias, collection)
      copy_thumbnails(title, medias)
      create_nfos(title, medias, collection)
    end

    # set file and directory permissions
    AppConfig[:directories].each { |dir| set_permissions(dir) }
  end

  # generate the report.
  # Note, must be ran after execute()
  # returns an array of lines
  def report
    buf = []
    unless DvdProfiler2Xbmc.interrupted?
      unless @media_files.nil?
        duplicates = duplicates_report
        unless duplicates.empty?
          buf << "Duplicates:\n"
          buf += duplicates
        end

        missing_isbns = missing_isbn_report
        unless missing_isbns.empty?
          buf += missing_isbns
        end
      end
    end
    buf
  end

  protected

  # find ISBN for each title and assign to the media
  def find_isbns(title, medias, collection)
    title_pattern = Collection.title_pattern(title)
    unless collection.title_isbn_hash[title_pattern].nil?
      medias.each do |media|
        media.isbn = collection.title_isbn_hash[title_pattern]
      end
    end
  end

  # copy images from .../isbn.jpg to .../basename.jpg
  def copy_thumbnails(title, medias)
    medias.each do |media|
      unless media.isbn.nil?
        media.isbn.each do |isbn|
          src_image_filespec = File.join(AppConfig[:images_dir], "#{isbn}f.jpg")
          if File.exist?(src_image_filespec)
            dest_image_filespec = media.path_to(:thumbnail_extension)
            begin
              File.copy(src_image_filespec, dest_image_filespec)
            rescue Exception => e
              AppConfig[:logger].error {e.to_s}
            end
          end
        end
      end
    end
  end

  # create nfo files from collection.isbn_dvd_hash
  def create_nfos(title, medias, collection)
    medias.each do |media|
      dvd_hash = (media.isbn.nil? ? nil : collection.isbn_dvd_hash[media.isbn.first])
      nfo = NFO.new(media, dvd_hash)
      nfo.save
    end
  end

  # set the directory and file permissions for all files and directories under
  # the given directory
  def set_permissions(dir)
    Dir.glob(File.join(dir, '**/*')).each do |f|
      begin
        if File.directory?(f)
          File.chmod(AppConfig[:dir_permissions], f) unless AppConfig[:dir_permissions].nil?
        else
          File.chmod(AppConfig[:file_permissions], f) unless AppConfig[:file_permissions].nil?
        end
      rescue Exception => e
        AppConfig[:logger].error {e.to_s}
      end
    end
  end

  # duplicate media file report
  def duplicates_report
    buf = []
    duplicates = @media_files.duplicate_titles
    unless duplicates.empty?
      duplicates.each do |title, medias|
        if medias.length > 1
          buf << title
          medias.each {|media| buf << "  #{media.media_path}"}
        end
      end
    end
    buf
  end

  # unable to find ISBN for these titles report
  def missing_isbn_report
    buf = []
    @media_files.titles.each do |title, medias|
      if medias.nil?
        buf << "No media for #{title}"
      else
        if medias[0].isbn.nil?
          buf << "ISBN not found for #{title}"
          medias.each {|media| buf << "  #{media.media_path}"}
        end
      end
    end
    buf
  end

end

