
# == Synopsis
# NFO (info) files
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

  def self.update(media)
    NfoController.new(media).update
  end

  def initialize(media)
    @media = media
    @info = Hash.new
    @xbmc_info = XbmcInfo.new(@media.path_to(:nfo))
    self.isbn = @xbmc_info.movie['isbn']
    self.imdb_id = @xbmc_info.movie['id']
  end

  # merge meta-data from the DVD Profiler collection.xml and from IMDB
  # into the @movie hash
  def update
    result = false
    begin
      AppConfig[:logger].info { "\n#{@media.title}" }
      @info.merge!(@xbmc_info.movie)

      dvd_hash = load_dvdprofiler
      imdb_hash = load_imdb(dvd_hash)
      tmdb_hash = load_tmdb

      @info.merge!(tmdb_hash_to_info(tmdb_hash))
      @info.merge!(imdb_hash_to_info(imdb_hash))
      @info.merge!(dvd_hash_to_info(dvd_hash))

      genres = @info['genre']
      genres ||= []
      genres += @media.media_subdirs.split('/') if AppConfig[:subdirs_as_genres]
      new_genres = map_genres(genres.uniq).uniq.compact
      @info['genre'] = new_genres unless new_genres.blank?

      save
      result = true
    rescue Exception => e
      AppConfig[:logger].error { "Error updating \"#{@media.path_to(:nfo)}\" - " + e.to_s + "\n" + e.backtrace.join("\n") }
      raise e
    end
    result
  end

  # return the ISBN or nil
  def isbn
    unless @info['isbn'].blank?
      @media.isbn ||= [@info['isbn']].flatten.uniq.compact.first.to_s
    end
    @media.isbn
  end

  # set the ISBN
  def isbn=(n)
    @media.isbn = n.to_s unless n.blank?
    @media.isbn
  end

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

  # load from the collection
  # return movie hash
  def load_dvdprofiler
    dvd_hash = Hash.new
    # find ISBN for each title and assign to the media
    profiles = DvdprofilerProfile.all(:isbn => self.isbn, :title => @media.title, :year => @media.year)
    if profiles.length > 1
      title = "#{@media.title}#{@media.year.blank? ? '' : ' (' + @media.year + ')'}"
      Dvdprofiler2Xbmc.multiple_profiles << "#{title} #{profiles.collect{|prof| prof.isbn}.join(", ")}"
      AppConfig[:logger].warn { "Multiple profiles found for #{title}" }
    else
      profile = profiles.first
      unless profile.nil?
        self.isbn ||= profile.isbn
        AppConfig[:logger].info { "ISBN => #{self.isbn}" } unless self.isbn.nil?
        profile.save(@media.path_to(:dvdprofiler_xml))
        dvd_hash = profile.dvd_hash
        @media.year = [dvd_hash[:productionyear]].flatten.sort.first if @media.year.blank? && !dvd_hash[:productionyear].blank?
      end
    end
    dvd_hash
  end

  # load data from IMDB.com
  # return movie hash
  def load_imdb(dvd_hash)
    imdb_hash = Hash.new
    unless File.exist?(@media.path_to(:no_imdb_lookup))
      profile = ImdbProfile.first(:imdb_id => self.imdb_id,
                                  :titles => self.get_imdb_titles(dvd_hash),
                                  :media_years => [@media.year.to_i],
                                  :production_years => dvd_hash[:productionyear],
                                  :released_years => dvd_hash[:released],
                                  :filespec => @media.path_to(:imdb_xml),
                                  :logger => AppConfig[:logger]
                                  )
      unless profile.nil?
        self.imdb_id ||= profile.imdb_id
        AppConfig[:logger].info { "IMDB ID => #{self.imdb_id}" } unless self.imdb_id.nil?
        imdb_hash = profile.movie
      end
    end
    imdb_hash
  end

  # load data form themovieDb.com
  # return movie hash
  def load_tmdb
    tmdb_hash = Hash.new
    unless File.exist?(@media.path_to(:no_tmdb_lookup))
      profile = TmdbProfile.first(:imdb_id => self.imdb_id,
                                  :api_key => TMDB_API_KEY,
                                  :filespec => @media.path_to(:tmdb_xml))
      unless profile.nil?
        tmdb_hash = profile.movie
      end
    end
    tmdb_hash
  end

  def get_imdb_titles(dvd_hash)
    titles = []
    titles << @info['title'] unless @info['title'].blank?
    titles << @media.title unless @media.title.blank?
    titles += get_parent_titles(dvd_hash)
    titles.uniq.compact
  end

  # try to find box set parent's title
  def get_parent_titles(dvd_hash)
    titles = []
    unless dvd_hash[:boxset].blank?
      begin
        AppConfig[:logger].info { "Need to find box set parent's title" }
        parent_isbn = dvd_hash[:boxset].first['parent'].first
        unless parent_isbn.blank?
          parent_profile = DvdprofilerProfile.first(:isbn => parent_isbn)
          unless parent_profile.blank?
            titles << parent_profile.title
            titles += get_parent_titles(parent_profile.dvd_hash)
          end
        end
      rescue
      end
    end
    AppConfig[:logger].info { "parent titles => #{titles.pretty_inspect}" } unless titles.empty?
    titles
  end

  DVD_HASH_TO_INFO_MAP =     {
      :rating         => 'mpaa',
      :plot           => 'outline',
      :overview       => 'plot',
      :runningtime    => 'runtime',
      :actors         => 'actor',
      :isbn           => 'isbn',
      :imdb_id        => 'id',
      :directors      => 'director'
      # Unused => :ProfileTimestamp, :ID, :MediaTypes, :UPC, :CollectionNumber
      # :CollectionType, :DistTrait, :OriginalTitle, :CountryOfOrigin
      # :ProductionYear, :RunningTime, :RatingSystem, :RatingAge, :RatingVariant
      # :CaseType, :Genres, :Regions, :Format, :Features, :Studios, :MediaCompanies
      # :Audio, :Subtitles, :'SRP DenominationType', :Actors, :Credits, :Overview
      # :EasterEggs, :Disks, :SortTitle, :LastEdited, :WishPriority, :PurchaseInfo
      # :Review, :Events, :BoxSet, :LoanInfo, :Notes, :Tags, :Locks
    }

  # map the given dvd_hash into a @movie hash
  def dvd_hash_to_info(dvd_hash)
    info = Hash.new
    unless dvd_hash.nil?
      dvd_hash[:genres] ||= []
      info['genre'] = dvd_hash[:genres] unless dvd_hash[:genres].blank?
      info['title'] = dvd_hash[:title]
      info['year']  = [dvd_hash[:productionyear], dvd_hash[:released]].flatten.uniq.collect{|s| ((s =~ /(\d{4})/) ? $1 : nil)}.uniq.compact.first
      DVD_HASH_TO_INFO_MAP.each do |key, value|
        info[value] = dvd_hash[key] unless dvd_hash[key].blank?
      end
    end
    info
  end

  def to_first_year(value)
    [value]
  end

  IMDB_HASH_TO_INFO_MAP = {
      'title'           => 'title',
      'mpaa'            => 'mpaa',
      'rating'          => 'rating',
      'plot'            => 'plot',
      'tagline'         => 'tagline',
      'year'            => 'year',
      'directors'       => 'director',
      'length'          => 'runtime',
      'genres'          => 'genre',
      'id'              => 'id',
      # Unused: 'company', 'countries', 'poster_url', 'writers', 'photos'
      # 'poster', 'color', 'aspect_ratio', 'languages', 'release_date'
      # 'tiny_poster_url', 'also_known_as'
    }
  def imdb_hash_to_info(imdb_hash)
    info = Hash.new
    unless imdb_hash.blank?
      IMDB_HASH_TO_INFO_MAP.each do |key, value|
        info[value] = imdb_hash[key] unless imdb_hash[key].blank?
      end
      info['id'] = self.imdb_id if info['id'].blank?
      # special cases:
      if info['mpaa'].blank? && !imdb_hash['certifications'].blank?
        imdb_hash['certifications'].each do |certs|
          if certs['country'] == 'USA'
            AppConfig[:logger].info { "Using alternative USA certification instead of mpaa rating" }
            info['mpaa'] = certs['rating'] unless certs['rating'].blank?
            break
          end
        end
      end
      unless imdb_hash['cast_members'].blank?
        imdb_hash['cast_members'].each do |anon|
          # anon[2] => {name,role}
          info['actor'] ||= []
          info['actor'] << {'name' => anon[0], 'role' => anon[1]}
        end
      end
      info['year'] ||= imdb_hash['release_year']
    end
    info
  end

  TMDB_HASH_TO_INFO_MAP = {
      # urls
      # scores
      # idents
      # titles
      # imdb_ids
      # alternative_titles
      # posters
      # types
      # fanarts
      'short_overviews' => 'plot',
      'releases' => 'year'
    }
  def tmdb_hash_to_info(tmdb_hash)
    info = Hash.new
    unless tmdb_hash.blank?
      TMDB_HASH_TO_INFO_MAP.each do |key, value|
        info[value] = tmdb_hash[key].first unless tmdb_hash[key].blank?
      end
    end
    info
  end

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

