class ImdbInfo

  protected
  # only instantiate via ImdbInfo.find(...)
  def initialize(profile)
    @profile = profile
  end

  public
  # == Synopsis
  # See ImdbProfile.all for options
  def self.find(options)
    imdb_info = nil
    profile = ImdbProfile.first(options)
    unless profile.nil?
      imdb_info = ImdbInfo.new(profile)
    end
    imdb_info
  end

  protected
  # == Synopsis
  # maps the imdb.movie hash to the info hash
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

  public

  # == Synopsis
  # maps the imdb.movie hash to the info hash
  def to_xbmc_info
    info = Hash.new
    unless @profile.movie.blank?
      IMDB_HASH_TO_INFO_MAP.each do |key, value|
        info[value] = @profile.movie[key] unless @profile.movie[key].blank?
      end
      info['id'] = self.imdb_id if info['id'].blank?
      # special cases:
      if info['mpaa'].blank? && !@profile.movie['certifications'].blank?
        @profile.movie['certifications'].each do |certs|
          if certs['country'] == 'USA'
            AppConfig[:logger].info { "Using alternative USA certification instead of mpaa rating" }
            info['mpaa'] = certs['rating'] unless certs['rating'].blank?
            break
          end
        end
      end
      unless @profile.movie['cast_members'].blank?
        @profile.movie['cast_members'].each do |anon|
          # anon[2] => {name,role}
          info['actor'] ||= []
          info['actor'] << {'name' => anon[0], 'role' => anon[1]}
        end
      end
      info['year'] ||= @profile.movie['release_year']
    end
    info
  end

  def imdb_id
    @profile.imdb_id rescue nil
  end
end
