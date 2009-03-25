
# == Synopsis
# NFO (info) files
#
# the @movie hash has keys that map directly to the .nfo file
# the @dvd_hash has keys that map to DVD Profiler's Collection.xml file
class NFO
  def initialize(media, collection)
    @media = media
    @collection = collection
    @dvd_hash = {}
    @movie = {}
  end

  # load the .nfo file into the @movie hash
  def load
    nfo_filespec = @media.path_to(:nfo_extension)
    begin
      if File.exist?(nfo_filespec) && (File.size(nfo_filespec) > 1)
        File.open(nfo_filespec) do |file|
          @movie = XmlSimple.xml_in(file)
          @original_movie = @movie.dup
          self.isbn = @movie['isbn']
          self.imdb_id = @movie['id']
        end
      end
    rescue Exception => e
      AppConfig[:logger].error { "Error loading \"#{nfo_filespec}\" - " + e.to_s + "\n" + e.backtrace.join("\n") }
      raise e
    end
  end

  # merge meta-data from the DVD Profiler collection.xml and from IMDB
  # into the @movie hash
  def update
    begin
      load_from_collection
      if AppConfig[:imdb_query] && self.imdb_id.blank?
        load_from_imdb
      end
      @movie.merge!(to_movie(@dvd_hash))
    rescue Exception => e
      AppConfig[:logger].error { "Error updating \"#{nfo_filespec}\" - " + e.to_s + "\n" + e.backtrace.join("\n") }
      raise e
    end
  end

  # save as a .nfo file, creating a backup if the .nfo already exists
  def save
    begin
      unless @movie.empty?
        @movie['title'] = @media.title if @movie['title'].blank?
        nfo_filespec = @media.path_to(:nfo_extension)
        if dirty? || !File.exist?(nfo_filespec)
          new_filespec = nfo_filespec + '.new'
          File.open(new_filespec, "w") do |file|
            file.puts(to_xml)
          end
          nfo_backup_filespec = @media.path_to(:nfo_backup_extension)
          File.delete(nfo_backup_filespec) if File.exist?(nfo_backup_filespec)
          File.rename(nfo_filespec, nfo_backup_filespec) if File.exist?(nfo_filespec)
          File.rename(new_filespec, nfo_filespec)
          AppConfig[:logger].info { "updated #{nfo_filespec}"}
          File.delete(new_filespec) if File.exist?(new_filespec)
        end
      end
    rescue Exception => e
      AppConfig[:logger].error { "Error saving nfo file - " + e.to_s + "\n" + e.backtrace.join("\n")}
    end
  end

  def dirty?
    result = false
    if @original_movie.nil?
      result = true
    else
      @movie.each do |key, value|
        if @original_movie[key].nil?
          result = true
          break
        end
        if @movie[key].to_s != @original_movie[key].to_s
          result = true
          break
        end
      end
      unless result
        diff_keys = @movie.keys.sort - @original_movie.keys.sort
        unless diff_keys.empty?
          result = true
        end
      end
    end
    result
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
  end

  # set the IMDB ID
  def imdb_id=(id)
    @dvd_hash[:imdb_id] = id.to_s unless id.blank?
  end

  protected

  # load @dvd_hash from the collection
  def load_from_collection
    # find ISBN for each title and assign to the media
    if self.isbn.nil?
      title_pattern = Collection.title_pattern(@media.title)
      unless @collection.title_isbn_hash[title_pattern].nil?
        self.isbn = [@collection.title_isbn_hash[title_pattern]].flatten.uniq.compact.first
      end
    end

    # merge the meta-data from the collection to dvd_hash
    unless self.isbn.blank?
      collection_hash = @collection.isbn_dvd_hash[self.isbn]
      @dvd_hash.merge!(collection_hash) unless collection_hash.blank?
    end
  end

  # load data from IMDB.com and merge into the @dvd_hash
  def load_from_imdb
    unless File.exist?(@media.path_to(:no_imdb_extension))
      years = (@media.year.nil? ? released_years(@dvd_hash) : [@media.year])
      title = (@dvd_hash[:title].nil? ? @media.title : @dvd_hash[:title])
      self.imdb_id = imdb_lookup(title, years) if self.imdb_id.blank?
      unless self.imdb_id.nil?
        imdb_movie = ImdbMovie.new(self.imdb_id.gsub(/^tt/, ''))
        @dvd_hash.merge!(to_dvd_hash(imdb_movie))
      end
    end
  end

  # convert the @movie hash into xml and return the xml as a String
  def to_xml
    xml = ''
    begin
      xml = XmlSimple.xml_out(@movie, 'NoAttr' => true, 'RootName' => 'movie')
    rescue Exception => e
      AppConfig[:logger].error { "Error creating nfo file - " + e.to_s}
      raise e
    end
    xml
  end

  # try to find the imdb id for the movie
  def imdb_lookup(title, years)
    id = nil

    AppConfig[:logger].info { "Searching IMDB for \"#{title}\"" }
    unless title.blank?
      begin
        imdb_search = ImdbSearch.new(title)
        id = imdb_search.find_id(:years => years, :media_path => @media.media_path)
      rescue Exception => e
        AppConfig[:logger].error { "Error searching IMDB - " + e.to_s }
        AppConfig[:logger].error { e.backtrace.join("\n") }
      end
    end
    AppConfig[:logger].info { "IMDB id => #{id}" } unless id.nil?
    id
  end

  # Different databases seem to mix up released versus production years.
  # So we combine both into a Array of integer years.
  def released_years(dvd_hash)
    years = []
    unless dvd_hash[:productionyear].blank?
      years += dvd_hash[:productionyear].collect{|y| [y.to_i - 1, y.to_i, y.to_i + 1]}.flatten
    end
    unless dvd_hash[:released].blank?
      years += dvd_hash[:released].collect do |date|
        y = nil
        y = $1.to_i if date =~ /(\d{4})\-/
        y
      end
    end
    years.flatten.uniq.compact.sort
  end

  # given a ImdbMovie instance, extract meta-data into and return a dvd_hash
  def to_dvd_hash(imdb_movie)
    dvd_hash = {}
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
    movie = {}
    movie['title']   = dvd_hash[:title]
    movie['mpaa']    = dvd_hash[:rating]         unless dvd_hash[:rating].blank?
    movie['year']    = dvd_hash[:productionyear] unless dvd_hash[:productionyear].blank?
    movie['outline'] = dvd_hash[:overview]       unless dvd_hash[:overview].blank?
    movie['plot']    = dvd_hash[:plot]           unless dvd_hash[:plot].blank?
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

