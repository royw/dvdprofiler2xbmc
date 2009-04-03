require File.dirname(__FILE__) + '/spec_helper.rb'

require 'tempfile'

FULL_REGRESSION = false

# Time to add your specs!
# http://rspec.info/

describe "Profile finders" do

  before(:all) do
    logger = Log4r::Logger.new('dvdprofiler2xbmc')
    logger.outputters = Log4r::StdoutOutputter.new(:console)
    Log4r::Outputter[:console].formatter  = Log4r::PatternFormatter.new(:pattern => "%m")
    logger.level = Log4r::INFO
    AppConfig.default
    AppConfig[:logger] = logger
    AppConfig.load

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

  before(:each) do
    ImdbMovie.stub!(:use_html_cache).and_return(true)
  end

  unless FULL_REGRESSION
    it "should find some titles (quick regression)" do
      titles = [
#           'Alexander the Great',
#           'Anastasia',
#           'About a Boy',
#           'Gung Ho',
#           'Hot Shots',
#           'Meltdown',
#           'Oklahoma!',
#           'The Man From Snowy River',
#           'Rooster Cogburn',
          'batteries not included'
        ].collect{|title| Collection.title_pattern(title)}
      buf = regression(titles)
      buf.should be_empty
    end
  end

  if FULL_REGRESSION
    it "should find all Collection titles (full regression)" do
      profiles = Dvdprofiler.all
      titles = profiles.collect{|profile| profile.title}
      buf = regression(titles.sort)
      buf.should be_empty
    end
  end

  def regression(titles)
    buf = []
    count = 0
    titles.each do |title|
      puts "title => #{title}"
      dvdprofiler_profiles = DvdprofilerProfile.all(:title => title)
      if dvdprofiler_profiles.blank?
        buf << "Can not find profile for #{title}"
      else
        dvdprofiler_profile = dvdprofiler_profiles.first
        isbn = dvdprofiler_profile.isbn
        puts "ISBN => #{isbn}"
        unless @ignore_isbns.include?(isbn.to_s)
          dvd_hash = dvdprofiler_profile.dvd_hash
          unless dvd_hash[:genres].include?('Television')
            count += 1
            imdb_profile = ImdbProfile.first(:titles => [dvd_hash[:title], title],
                                     :production_years => dvd_hash[:productionyear],
                                     :released_years => dvd_hash[:released])
            if imdb_profile.blank?
              buf << "Can not find IMDB ID for #{isbn} #{title}"
            else
              puts "IMDB ID => #{imdb_profile.imdb_id}"
            end
          end
        end
      end
    end
    puts buf.join("\n") + "\n\m# movies: #{count}\n# missing IMDB ID: #{buf.size}"
    buf
  end

end
