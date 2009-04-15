# This is the model for the IDMB profile which is used
# to find ImdbMovie meta data from either online or from
# a cached file.
#
# Usage:
#
# profiles = ImdbProfile.all(:titles => ['The Alamo'])
#
# profile = ImdbProfile.first(:imdb_id => 'tt0123456')
# or
# profile = ImdbProfile.first(:titles => ['movie title 1', 'movie title 2',...]
#                             :media_years => ['2000'],
#                             :production_years => ['1999'],
#                             :released_years => ['2002', '2008']
#                             :filespec => media.path_to(:imdb_xml))
# puts profile.movie['key'].first
# puts profile.to_xml
# puts profile.imdb_id
#

# An optional logger.
# If initialized with a logger instance, uses the logger
# otherwise doesn't do anything.
# Basically trying to not require a particular logger class.
class OptionalLogger
  # logger may be nil or a logger instance
  def initialize(logger)
    @logger = logger
  end

  # debug {...}
  def debug(&blk)
    @logger.debug(blk.call) unless @logger.nil?
  end

  # info {...}
  def info(&blk)
    @logger.info(blk.call) unless @logger.nil?
  end

  # warn {...}
  def warn(&blk)
    @logger.warn(blk.call) unless @logger.nil?
  end

  # error {...}
  def error(&blk)
    @logger.error(blk.call) unless @logger.nil?
  end
end

class ImdbProfile

  # options:
  #   :imdb_id          => String containing the IMDB ID (ex: 'tt0465234')
  #                        Note, the leading 'tt' is optional.
  #   :titles           => titles,
  #   :media_years      => Array of integer, 4 digit years (ex: [1998]).
  #                        Should be the year(s) from the media file name.
  #                        This let's the user say what year when they name
  #                        the file.
  #   :production_years => Array of integer, 4 digit years (ex: [1997,1998]).
  #                        Should be the year(s) the movie was made.
  #                        Note, some databases differ on the production year.
  #   :released_years   => Array of integer, 4 digit years (ex: [1998, 2008])
  #                        Should be the year(s) the movie was released.
  #   :logger           => Logger instance
  # returns Array of ImdbProfile instances
  def self.all(options={})
    @class_logger = OptionalLogger.new(options[:logger])
    @class_logger.debug {"ImdbProfile.all(#{options.inspect})"} unless options[:logger].nil?
    result = []
    if has_option?(options, :imdb_id) || (has_option?(options, :filespec) && File.exist?(options[:filespec]))
      result << ImdbProfile.new(options[:imdb_id], options[:filespec], options[:logger])
    elsif has_option?(options, :titles)
      result += self.lookup(options[:titles],
                            options[:media_years],
                            options[:production_years],
                            options[:released_years]
                          ).collect{|ident| ImdbProfile.new(ident, options[:filespec], options[:logger])}
    end
    result
  end

  # see ImdbProfile.all for options description
  def self.first(options={})
    self.all(options).first
  end

  protected

  def self.has_option?(options, key)
    options.has_key?(key) && !options[key].blank?
  end

  def initialize(ident, filespec, logger)
    @imdb_id = ident

    @filespec = filespec
    @logger = OptionalLogger.new(logger)
    load
  end

  public

  # returns the IMDB ID String
  attr_reader :imdb_id

  # returns a Hash with the movie's meta data generated from ImdbMovie.to_hash.
  # See ImdbMovie for details.
  attr_reader :movie

  # return the xml as a String
  def to_xml
    xml = ''
    unless @movie.blank?
      @movie.delete_if { |key, value| value.nil? }
      xml = XmlSimple.xml_out(@movie, 'NoAttr' => true, 'RootName' => 'movie')
    end
    xml
  end

  protected

  # @movie keys => [:title, :directors, :poster_url, :tiny_poster_url, :poster,
  #                 :rating, :cast_members, :writers, :year, :genres, :plot,
  #                 :tagline, :aspect_ratio, :length, :release_date, :countries,
  #                 :languages, :color, :company, :photos, :raw_title,
  #                 :release_year, :also_known_as, :mpaa, :certifications]
  # returns Hash or nil
  def load
    if !@filespec.blank? && File.exist?(@filespec)
      @logger.debug { "loading movie filespec=> #{@filespec.inspect}" }
      @movie = from_xml(open(@filespec).read)
    elsif !@imdb_id.blank?
      @logger.debug { "loading movie from imdb.com, filespec=> #{@filespec.inspect}" }
      @movie = ImdbMovie.new(@imdb_id.gsub(/^tt/, '')).to_hash
      @movie['id'] = 'tt' + @imdb_id.gsub(/^tt/, '') unless @movie.blank?
      save(@filespec) unless @filespec.blank?
    end
    unless @movie.blank?
      @imdb_id = @movie['id']
      @imdb_id = @imdb_id.first if @imdb_id.respond_to?('[]') && @imdb_id.length == 1
    else
      @movie = nil
    end
  end

  def from_xml(xml)
    begin
      movie = XmlSimple.xml_in(xml)
    rescue Exception => e
      @logger.warn { "Error converting from xml: #{e.to_s}" }
      movie = nil
    end
    movie
  end

  def save(filespec)
    begin
      xml = self.to_xml
      unless xml.blank?
        @logger.debug { "saving #{filespec}" }
        DvdProfiler2Xbmc.save_to_file(filespec, xml)
      end
    rescue Exception => e
      @logger.error "Unable to save imdb profile to #{filespec} - #{e.to_s}"
    end
  end

  # lookup IMDB title using years as the secondary search key
  # the titles should behave as an Array, the intent here is to be
  # able to try to find the exact title from DVD Profiler and if that
  # fails, to try to find the title pattern
  # The search order is:
  # 1) media_years should be from media filename
  # 2) production years
  # 3) production years plus/minus a year
  # 4) released years
  # 5) released years plus/minus a year
  # 6) no years
  def self.lookup(titles, media_years, production_years, released_years)
    idents = []
    year_sets = []
    year_sets << media_years unless media_years.blank?
    year_sets << fuzzy_years(production_years, 0) unless production_years.blank?
    year_sets << fuzzy_years(production_years, -1..1) unless production_years.blank?
    year_sets << fuzzy_years(released_years, 0) unless released_years.blank?
    year_sets << fuzzy_years(released_years, -1..1) unless released_years.blank?
    year_sets << [] if media_years.blank?

    titles.flatten.uniq.compact.each do |title|
      [false, true].each do |search_akas|
        @class_logger.debug { (search_akas ? 'Search AKAs' : 'Do not search AKAs') }
        imdb_search = ImdbSearch.new(title, search_akas)
        @cache ||= {}
        imdb_search.set_cache(@cache)

        if year_sets.flatten.uniq.compact.empty?
          idents = imdb_search.movies.collect{|m| m.id.to_s}.uniq.compact
        else
          year_sets.each do |years|
            new_idents = find_id(imdb_search, title, years, search_akas)
            @class_logger.debug { "new_idents => #{new_idents.inspect}" }
            idents += new_idents
            break unless new_idents.blank?
          end
        end
        break unless idents.blank?
      end
      break unless idents.blank?
    end
    idents.uniq.compact
  end

  # Different databases seem to mix up released versus production years.
  # So we combine both into a Array of integer years.
  # fuzzy is an integer range, basically expand each known year by the fuzzy range
  # i.e., let production and released year both be 2000 and fuzzy=-1..1,
  # then the returned years would be [1999, 2000, 2001]
  def self.fuzzy_years(source_years, fuzzy)
    years = []
    unless source_years.blank?
      years = [source_years].flatten.collect do |date|
        a = []
        if date.to_s =~ /(\d{4})/
          y = $1.to_i
          a = [*fuzzy].collect do
            |f| y.to_i + f
          end
        end
        a
      end
    end
    result = years.flatten.uniq.compact.sort
    result
  end

  # try to find the imdb id for the movie
  def self.find_id(imdb_search, title, years, search_akas)
    idents = []

    @class_logger.info { "Searching IMDB for \"#{title}\" (#{years.join(", ")})" }
    unless title.blank?
      begin
        movies = imdb_search.movies
        @class_logger.debug { "movies => (#{movies.collect{|m| [m.id, m.year, m.title]}.inspect})"}
        if movies.size == 1
          idents = [movies.first.id.to_s]
        elsif movies.size > 1
          @class_logger.debug { "years => #{years.inspect}"}
          same_year_movies = movies.select{ |m| !m.year.blank? && years.include?(m.year.to_i) }
          idents = same_year_movies.collect{|m| m.id.to_s}
          @class_logger.debug { "same_year_movies => (#{same_year_movies.collect{|m| [m.id, m.year, m.title]}.inspect})"}
        end
      rescue Exception => e
        @class_logger.error { "Error searching IMDB - " + e.to_s }
        @class_logger.error { e.backtrace.join("\n") }
      end
    end
    @class_logger.debug { "IMDB id => #{idents.join(', ')}" } unless idents.blank?
    idents
  end

end
