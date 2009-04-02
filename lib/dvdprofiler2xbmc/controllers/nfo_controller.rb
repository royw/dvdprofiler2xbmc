
# == Synopsis
# NFO (info) files
#
# the @movie hash has keys that map directly to the .nfo file
# the @dvd_hash has keys that map to DVD Profiler's Collection.xml file
class NfoController
  def initialize(media)
    @media = media
    @dvd_hash = Hash.new
    @movie = Hash.new
    @xbmc_info = XbmcInfo.new(@media.path_to(:nfo_extension))
    self.isbn = @xbmc_info.movie['isbn']
    self.imdb_id = @xbmc_info.movie['id']
  end

  # merge meta-data from the DVD Profiler collection.xml and from IMDB
  # into the @movie hash
  def update
    begin
      AppConfig[:logger].info { "\n#{@media.title}" }
      @movie.merge!(@xbmc_info.movie)
      @dvd_hash.merge!(load_dvdprofiler)
      if AppConfig[:imdb_query] && (self.imdb_id.blank? || AppConfig[:force_nfo_replacement])
        @dvd_hash.merge!(load_imdb)
      end
      @movie.merge!(to_movie(@dvd_hash))
    rescue Exception => e
      AppConfig[:logger].error { "Error updating \"#{@media.path_to(:nfo_extension)}\" - " + e.to_s + "\n" + e.backtrace.join("\n") }
      raise e
    end
  end

  protected

  # load @dvd_hash from the collection
  def load_dvdprofiler
    dvd_hash = Hash.new
    # find ISBN for each title and assign to the media
    profile = DvdprofilerProfile.first(:isbn => self.isbn, :title => @media.title)
    unless profile.nil?
      self.isbn ||= profile.isbn
      AppConfig[:logger].info { "ISBN => #{self.isbn}" } unless self.isbn.nil?
      profile.save(@media.path_to(:dvdprofiler_xml_extension))
      dvd_hash = profile.dvd_hash
    end
    dvd_hash
  end

  # load data from IMDB.com and merge into the @dvd_hash
  def load_imdb
    dvd_hash = Hash.new
    unless File.exist?(@media.path_to(:no_imdb_extension))
      profile = ImdbProfile.first(:imdb_id => self.imdb_id,
                                  :titles => self.get_imdb_titles,
                                  :media_years => [@media.year.to_i],
                                  :production_years => @dvd_hash[:productionyear],
                                  :released_years => @dvd_hash[:released]
                                  )
      unless profile.nil?
        self.imdb_id ||= profile.imdb_id
        AppConfig[:logger].info { "IMDB ID => #{self.imdb_id}" } unless self.imdb_id.nil?
        profile.save(@media.path_to(:imdb_xml_extension))
        dvd_hash = to_dvd_hash(profile.movie)
      end
    end
    dvd_hash
  end

  public

  # save as a .nfo file, creating a backup if the .nfo already exists
  def save
    begin
      unless @movie.empty?
        @movie['title'] = @media.title if @movie['title'].blank?
        @xbmc_info.movie = @movie
        @xbmc_info.save
      end
    rescue Exception => e
      AppConfig[:logger].error { "Error saving nfo file - " + e.to_s + "\n" + e.backtrace.join("\n")}
    end
  end

  # return the ISBN or nil
  def isbn
    if @dvd_hash[:isbn].blank? && !@movie['isbn'].blank?
      @dvd_hash[:isbn] = [@movie['isbn']].flatten.uniq.compact.first.to_s
    end
    @dvd_hash[:isbn]
  end

  # set the ISBN
  def isbn=(n)
    @dvd_hash[:isbn] = n.to_s unless n.blank?
  end

  # return the IMDB ID or nil
  def imdb_id
    if @dvd_hash[:imdb_id].nil? && !@movie['id'].blank?
      @dvd_hash[:imdb_id] = @movie['id'].to_s
    end
    unless @dvd_hash[:imdb_id].nil?
      # make sure is not an array
      @dvd_hash[:imdb_id] = [@dvd_hash[:imdb_id].to_s].flatten.uniq.compact.first
    end
    ident = @dvd_hash[:imdb_id]
    unless ident.blank? || (ident.to_s =~ /^tt\d+$/)|| (ident.to_s =~ /^\d+$/)
      AppConfig[:logger].warn { "Attempting to return invalid IMDB ID: \"#{ident}\"" }
    end
    ident
  end

  # set the IMDB ID
  def imdb_id=(ident)
    if ident.blank?
      @dvd_hash[:imdb_id] = nil
    elsif (ident.to_s =~ /^tt\d+$/) || (ident.to_s =~ /^\d+$/)
      @dvd_hash[:imdb_id] = ident.to_s
    else
      AppConfig[:logger].warn { "Attempting to set invalid IMDB ID: \"#{ident}\"" }
    end
  end

  protected

#   def save_to_file(filespec, data)
#     new_filespec = filespec + AppConfig[:new_extension]
#     File.open(new_filespec, "w") do |file|
#       file.puts(data)
#     end
#     backup_filespec = filespec + AppConfig[:backup_extension]
#     File.delete(backup_filespec) if File.exist?(backup_filespec)
#     File.rename(filespec, backup_filespec) if File.exist?(filespec)
#     File.rename(new_filespec, filespec)
#     File.delete(new_filespec) if File.exist?(new_filespec)
#   end

  def get_imdb_titles
    titles = []
    unless @dvd_hash[:title].blank?
      titles << @dvd_hash[:title]
    end
    unless @media.title.blank?
      titles << @media.title
    end
    titles.uniq.compact
  end

#   # convert the @movie hash into xml and return the xml as a String
#   def to_xml
#     xml = ''
#     begin
#       xml = XmlSimple.xml_out(@movie, 'NoAttr' => true, 'RootName' => 'movie')
#     rescue Exception => e
#       AppConfig[:logger].error { "Error creating nfo file - " + e.to_s}
#       raise e
#     end
#     xml
#   end

  # given a ImdbMovie instance, extract meta-data into and return a dvd_hash
  def to_dvd_hash(imdb_movie)
    dvd_hash = Hash.new
    dvd_hash[:title]          = imdb_movie.title
    dvd_hash[:imdb_id]        = 'tt' + imdb_movie.id.gsub(/^tt/,'') unless imdb_movie.id.blank?
    dvd_hash[:rating]         = imdb_movie.mpaa
    dvd_hash[:rating]         ||= imdb_movie.certifications['USA']
    dvd_hash[:productionyear] = imdb_movie.release_year
    dvd_hash[:plot]           = imdb_movie.plot
    dvd_hash[:runningtime]    = imdb_movie.length
    dvd_hash[:genre]          = imdb_movie.genres
    dvd_hash[:actor]          = imdb_movie.cast_members
    dvd_hash
  end

  # map the given dvd_hash into a @movie hash
  def to_movie(dvd_hash)
    dvd_hash[:genres] ||= []
    genres = map_genres((dvd_hash[:genres] + @media.media_subdirs.split('/')).uniq)
    movie = Hash.new
    movie['title']   = dvd_hash[:title]
    movie['mpaa']    = dvd_hash[:rating]         unless dvd_hash[:rating].blank?
    movie['year']    = dvd_hash[:productionyear] unless dvd_hash[:productionyear].blank?
    movie['outline'] = dvd_hash[:plot]           unless dvd_hash[:plot].blank?
    movie['plot']    = dvd_hash[:overview]       unless dvd_hash[:overview].blank?
    movie['runtime'] = dvd_hash[:runningtime]    unless dvd_hash[:runningtime].blank?
    movie['actor']   = dvd_hash[:actors]         unless dvd_hash[:actors].blank?
    movie['isbn']    = dvd_hash[:isbn]           unless dvd_hash[:isbn].blank?
    movie['id']      = dvd_hash[:imdb_id]        unless dvd_hash[:imdb_id].blank?
    movie['genre']   = genres                    unless genres.blank?
    movie
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

