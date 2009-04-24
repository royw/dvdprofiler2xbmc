require File.dirname(__FILE__) + '/spec_helper.rb'

require 'tempfile'

FULL_REGRESSION = true

# Time to add your specs!
# http://rspec.info/

describe "Dvdprofiler2xbmc" do

  before(:all) do
    logger = Log4r::Logger.new('dvdprofiler2xbmc')
    logger.outputters = Log4r::StdoutOutputter.new(:console)
    Log4r::Outputter[:console].formatter  = Log4r::PatternFormatter.new(:pattern => "%m")
    logger.level = Log4r::WARN
    AppConfig.default
    AppConfig[:logger] = logger
    AppConfig.load
    DvdprofilerProfile.collection_filespec = File.join(SAMPLES_DIR, 'Collection.xml')
    File.mkdirs(TMPDIR)

    # the ignore_isbns array contain ISBNs for titles that can not be looked up on IMDB,
    # i.e., sets ands really low volume/special interest titles.
    @ignore_isbns = [
      '837101098915', # mexico whitetails
      '018713811837.4', # pearl harbor payback appointment in tokyo
      '084296403196', # rodeo racketeers john wayne young duke series
      '018111247894', # seabiscuit america s legendary racehorse
      '097360612547', # the adventures of indiana jones the complete dvd movie collection
      '096009099596', # the great american western volume 6
      '025192829925', # the mummy collector s set
      '707729138280'  # topper topper and topper returns
      ]
  end

  describe "Regression" do
    unless FULL_REGRESSION
      it "should find some titles (quick regression)" do
        titles = [
            'Alexander the Great',
            'Anastasia',
            'About a Boy',
            'Gung Ho',
            'Hot Shots',
            'Meltdown',
            'Oklahoma!',
            'The Man From Snowy River',
            'Rooster Cogburn (...and the Lady)',
            'Call Me The Rise And Fall of Heidi Fleiss',
            'batteries not included',
            'Flyboys',
            "Captain Corelli's Mandolin",
          ].collect{|title| Collection.title_pattern(title)}
        buf = regression(titles)
        buf.should be_empty
      end
    end

    if FULL_REGRESSION
      DvdprofilerProfile.collection_filespec = File.join(SAMPLES_DIR, 'Collection.xml')
      profiles = DvdprofilerProfile.all
      titles = profiles.collect{|profile| profile.title}
      titles.sort.each do |title|
        it "should find all Collection titles (full regression) title=>#{title}" do
          regression([title]).should == []
        end
      end
    end

    def regression(titles)
      buf = []
      count = 0
      titles.each do |title|
        AppConfig[:logger].debug "title => #{title}"
        dvdprofiler_profiles = DvdprofilerProfile.all(:title => title)
        if dvdprofiler_profiles.blank?
          buf << "Can not find profile for #{title}"
        else
          dvdprofiler_profile = dvdprofiler_profiles.first
          isbn = dvdprofiler_profile.isbn
          AppConfig[:logger].debug "ISBN => #{isbn}"
          unless @ignore_isbns.include?(isbn.to_s)
            dvd_hash = dvdprofiler_profile.dvd_hash
            unless dvd_hash[:genres].include?('Television')
              count += 1
              imdb_profile = ImdbProfile.first(:titles => [dvd_hash[:title], title, dvd_hash[:originaltitle]].uniq.compact,
                                      :production_years => dvd_hash[:productionyear],
                                      :released_years => dvd_hash[:released],
                                      :logger => AppConfig[:logger])
              if imdb_profile.blank?
                buf << "Can not find IMDB ID for #{isbn} #{title}"
              else
                AppConfig[:logger].debug "IMDB ID => #{imdb_profile.imdb_id}"
              end
            end
          end
        end
      end
      AppConfig[:logger].debug buf.join("\n") + "\n\m# movies: #{count}\n# missing IMDB ID: #{buf.size}"
      buf
    end
  end
end
