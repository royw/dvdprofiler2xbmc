class TmdbInfo

  def initialize(profile)
    @profile = profile
  end

  # == Synopsis
  # load data from themovieDb.com
  # see TmdbProfile.all for options
  def self.find(options)
    tmdb_info = nil
    profile = TmdbProfile.first(options)
    unless profile.nil?
      tmdb_info = TmdbInfo.new(profile)
    end
    tmdb_info
  end

  private

  # == Synopsis
  # map the tmdb.movie hash into the info hash
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

  public

  # == Synopsis
  # map the tmdb.movie hash into the info hash
  def to_xbmc_info
    info = Hash.new
    unless @profile.movie.blank?
      TMDB_HASH_TO_INFO_MAP.each do |key, value|
        info[value] = @profile.movie[key].first unless @profile.movie[key].blank?
      end
    end
    info
  end

end
