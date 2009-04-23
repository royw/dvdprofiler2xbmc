
# == Synopsis
# This is the heart and soul of the application.  This is
# where the different media meta data are merged into the
# info (.nfo) format needed by XBMC.
#
# TODO: This class is rather large and should be refactored.
#
# the @info hash has keys that map directly to the .nfo file
#
# Usage:
#  controller = NfoController.new(media)
#  controller.update
#  puts controller.isbn
#  puts controller.imdb_id
# or
#  NfoController.update(media)
class NfoController

  attr_reader :info

  # == Synopsis
  def self.update(media)
    NfoController.new(media).update
  end

  # == Synopsis
  def initialize(media)
    @media = media
    @info = Hash.new
    @xbmc_info = XbmcInfo.new(@media.path_to(:nfo))
    self.isbn = @xbmc_info.movie['isbn']
    self.imdb_id = @xbmc_info.movie['id']
  end

  # == Synopsis
  # merge meta-data from the DVD Profiler collection.xml and from IMDB
  # into the @movie hash
  def update
    result = false
    begin
      AppConfig[:logger].info { "\n#{@media.title}" }
      @info.merge!(@xbmc_info.movie)

      # load any manually cached IDs
      self.isbn ||= load_isbn_id
      self.imdb_id ||= load_imdb_id

      extra_titles = []
      production_years = []
      released_years = []

      dvdprofiler_info = load_dvdprofiler_info
      unless dvdprofiler_info.nil?
        original_titles = dvdprofiler_info.original_titles
        box_set_parent_titles = dvdprofiler_info.box_set_parent_titles
        extra_titles << dvdprofiler_info.title unless dvdprofiler_info.title.blank?
        extra_titles += original_titles unless original_titles.blank?
        extra_titles += box_set_parent_titles unless box_set_parent_titles.blank?
        production_years = dvdprofiler_info.production_years
        released_years = dvdprofiler_info.released_years
      end

      imdb_info = load_imdb_info(extra_titles, production_years, released_years)
      unless imdb_info.nil?
        self.imdb_id ||= imdb_info.imdb_id
      end

      tmdb_info = load_tmdb_info

      @info = merge(@info, dvdprofiler_info, imdb_info, tmdb_info)

      # map any genres
      @info['genre'] = remap_genres(@info['genre'])

      save
      result = true
    rescue Exception => e
      AppConfig[:logger].error { "Error updating \"#{@media.path_to(:nfo)}\" - " + e.to_s + "\n" + e.backtrace.join("\n") }
      raise e
    end
    result
  end

  # == Synopsis
  # return the ISBN or nil
  def isbn
    unless @info['isbn'].blank?
      @media.isbn ||= [@info['isbn']].flatten.uniq.compact.first.to_s
    end
    @media.isbn
  end

  # == Synopsis
  # set the ISBN
  def isbn=(n)
    @media.isbn = n.to_s unless n.blank?
    @media.isbn
  end

  # == Synopsis
  # return the IMDB ID or nil
  def imdb_id
    unless @info['id'].blank?
      # make sure is not an array
      @media.imdb_id ||= [@info['id'].to_s].flatten.uniq.compact.first
    end
    unless @media.imdb_id.blank? || (@media.imdb_id.to_s =~ /^tt\d+$/)|| (@media.imdb_id.to_s =~ /^\d+$/)
      AppConfig[:logger].warn { "Attempting to return invalid IMDB ID: \"#{@media.imdb_id}\"" }
    end
    @media.imdb_id
  end

  # == Synopsis
  # set the IMDB ID
  def imdb_id=(ident)
    if ident.blank?
      @media.imdb_id = nil
    elsif (ident.to_s =~ /^tt\d+$/) || (ident.to_s =~ /^\d+$/)
      @media.imdb_id = ident.to_s
    else
      AppConfig[:logger].warn { "Attempting to set invalid IMDB ID: \"#{ident}\"" }
    end
    @media.imdb_id
  end

  protected

  def load_dvdprofiler_info
    dvdprofiler_info = nil
    # load the profile infos
    dvdprofiler_info = DvdprofilerInfo.find(:isbn     => self.isbn,
                                            :title    => @media.title,
                                            :year     => @media.year,
                                            :filespec => @media.path_to(:dvdprofiler_xml))
    unless dvdprofiler_info.nil?
      self.isbn ||= dvdprofiler_info.isbn
      @media.year = dvdprofiler_info.year if(@media.year.blank? && !dvdprofiler_info.year.blank?)
    end
    dvdprofiler_info
  end

  def load_imdb_info(extra_titles, production_years, released_years)
    imdb_info = nil
    unless File.exist?(@media.path_to(:no_imdb_lookup))
      possible_imdb_titles = get_imdb_titles(extra_titles)
      imdb_info = ImdbInfo.find(:imdb_id => self.imdb_id,
                                :titles => possible_imdb_titles,
                                :media_years => [@media.year.to_i],
                                :production_years => production_years,
                                :released_years => released_years,
                                :filespec => @media.path_to(:imdb_xml),
                                :logger => AppConfig[:logger])
    end
    imdb_info
  end

  def load_tmdb_info
    tmdb_info = nil
    unless File.exist?(@media.path_to(:no_tmdb_lookup))
      tmdb_info = TmdbInfo.find(:imdb_id => self.imdb_id,
                                :api_key => TMDB_API_KEY,
                                :filespec => @media.path_to(:tmdb_xml))
    end
    tmdb_info
  end

  def merge(info, dvdprofiler_info, imdb_info, tmdb_info)
    # merge the profiles into the @info hash
    # Note, order is important as each overwrites what is previously in @info
    info.merge!(tmdb_info.to_xbmc_info) unless tmdb_info.nil?
    info.merge!(imdb_info.to_xbmc_info) unless imdb_info.nil?
    info.merge!(dvdprofiler_info.to_xbmc_info) unless dvdprofiler_info.nil?
    info
  end

  # == Synopsis
  # save as a .nfo file, creating a backup if the .nfo already exists
  def save
    begin
      unless @info.empty?
        @info['title'] = @media.title if @info['title'].blank?
        @xbmc_info.movie = @info
        @xbmc_info.save
      end
    rescue Exception => e
      AppConfig[:logger].error { "Error saving nfo file - " + e.to_s + "\n" + e.backtrace.join("\n")}
    end
  end

  # == Synopsis
  # load the ISBN from a manually created .isbn file
  def load_isbn_id
    ident = nil
    filespec = @media.path_to(:isbn)
    if File.exist?(filespec)
      ident = open(filespec).read.strip
    end
    ident
  end

  # == Synopsis
  # load the IMDB ID from a manually created .imdb file
  def load_imdb_id
    ident = nil
    filespec = @media.path_to(:imdb)
    if File.exist?(filespec)
      ident = open(filespec).read.strip
    end
    ident
  end

  # == Synopsis
  # get an Array of String titles
  def get_imdb_titles(extra_titles)
    titles = []
    titles << @info['title'] unless @info['title'].blank?
    titles << @media.title unless @media.title.blank?
    titles += extra_titles
    titles.uniq.compact
  end

  # == Synopsis
  # remap genres
  # genres => Array of String genres
  # returns Array of String genres
  def remap_genres(genres)
    genres ||= []
    genres += @media.media_subdirs.split('/') if AppConfig[:subdirs_as_genres]
    new_genres = map_genres(genres.uniq).uniq.compact
    new_genres = nil if new_genres.blank?
    new_genres
  end

  # == Synopsis
  # map the given genres using the AppConfig[:genre_maps].
  # given an Array of String genres
  # returns an Array of String genres that have been mapped, are unique, and do not include any nils
  def map_genres(genres)
    new_genres = []
    genres.each do |genre|
      new_genres << (AppConfig[:genre_maps][genre].nil? ? genre : AppConfig[:genre_maps][genre])
    end
    new_genres.uniq.compact
  end

end

