class DvdprofilerInfo

  def initialize(profile)
    @profile = profile
  end

  # == Synopsis
  # see DvdprofilerProfile.all for options
  # really should include at least:  :title, :year, :isbn, :filespec
  def self.find(options)
    dvdprofiler_info = nil
    # replace options[:year] => 0 with nil
    options[:year] = (options[:year].to_i > 0 ? options[:year] : nil) unless options[:year].blank?
    # find ISBN for each title and assign to the media
    profiles = DvdprofilerProfile.all(options)
    if profiles.length > 1
      media_title = "#{options[:title]}#{options[:year].blank? ? '' : ' (' + options[:year] + ')'}"
      DvdProfiler2Xbmc.multiple_profiles << "#{media_title} #{profiles.collect{|prof| prof.isbn}.join(", ")}"
      AppConfig[:logger].warn { "Multiple profiles found for #{media_title}" }
    else
      profile = profiles.first
      unless profile.nil?
        AppConfig[:logger].info { "ISBN => #{options[:isbn]}" } unless options[:isbn].nil?
        profile.save(options[:filespec])
        dvdprofiler_info = DvdprofilerInfo.new(profile)
      end
    end
    dvdprofiler_info
  end

  private

  # == Synopsis
  # maps the Dvdprofiler.dvd_hash to the info hash
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

  public

  # == Synopsis
  # map the given dvd_hash into a @movie hash
  def to_xbmc_info
    info = Hash.new
    unless @profile.dvd_hash.nil?
      @profile.dvd_hash[:genres] ||= []
      info['genre'] = @profile.dvd_hash[:genres] unless @profile.dvd_hash[:genres].blank?
      info['title'] = @profile.dvd_hash[:title]
      info['year']  = [@profile.dvd_hash[:productionyear], @profile.dvd_hash[:released]].flatten.uniq.collect{|s| ((s =~ /(\d{4})/) ? $1 : nil)}.uniq.compact.first
      DVD_HASH_TO_INFO_MAP.each do |key, value|
        info[value] = @profile.dvd_hash[key] unless @profile.dvd_hash[key].blank?
      end
    end
    info
  end

  def isbn
    @profile.isbn rescue nil
  end

  # == Synopsis
  # return the lowest production year as the year
  def year
    [@profile.dvd_hash[:productionyear]].flatten.uniq.compact.sort.first rescue nil
  end

  # == Synopsis
  # try to find box set parent's title
  def box_set_parent_titles
    titles = []
    unless @profile.dvd_hash[:boxset].blank?
      begin
        AppConfig[:logger].debug { "Need to find box set parent's title" }
        parent_isbn = @profile.dvd_hash[:boxset].first['parent'].first
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
    AppConfig[:logger].debug { "parent titles => #{titles.pretty_inspect}" } unless titles.empty?
    titles
  end

  def production_years
    @profile.dvd_hash[:productionyear] rescue []
  end

  def released_years
    @profile.dvd_hash[:released] rescue []
  end

  def original_titles
    titles = []
    originaltitle = @profile.dvd_hash[:originaltitle]
    titles = [originaltitle].flatten.uniq.compact unless originaltitle.blank?
    titles = titles.collect{|t| t.blank? ? nil : t}.compact
    titles
  end

  def title
    @profile.dvd_hash[:title] rescue nil
  end
end
