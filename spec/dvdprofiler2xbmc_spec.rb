require File.dirname(__FILE__) + '/spec_helper.rb'

# require File.dirname(__FILE__) + '/../lib/dvdprofiler2xbmc.rb'

require 'tempfile'

FULL_REGRESSION = false
TMPDIR = File.join(File.dirname(__FILE__), '../tmp')

# Time to add your specs!
# http://rspec.info/

describe "XbmcInfo" do
  before(:each) do
    logger = Log4r::Logger.new('dvdprofiler2xbmc')
    logger.outputters = Log4r::StdoutOutputter.new(:console)
    Log4r::Outputter[:console].formatter  = Log4r::PatternFormatter.new(:pattern => "%m")
    logger.level = Log4r::INFO
    AppConfig.default
    AppConfig[:logger] = logger
    AppConfig.load
    filespec = File.expand_path(File.join(File.dirname(__FILE__), 'samples/Die Hard - 1988.nfo'))
    @xbmc_info = XbmcInfo.new(filespec)
  end

  after(:each) do
    Dir.glob(File.join(TMPDIR,'xbmcinfo_*')).each { |filename| File.delete(filename) }
  end

  it "verify reading .nfo file" do
    @xbmc_info.movie['title'].first.should == 'Die Hard'
  end

  it "verify creating .nfo file" do
    outfile = Tempfile.new('xbmcinfo_spec_create', TMPDIR)
    new_xbmc_info = XbmcInfo.new(outfile.path)
    new_xbmc_info.movie = @xbmc_info.movie
    new_xbmc_info.save
    (File.exist?(outfile.path).should be_true) && (File.size(outfile.path).should > 0)
  end

  it "verify overwriting .nfo file" do
    outfile = Tempfile.new('xbmcinfo_spec_overwrite', TMPDIR)
    new_xbmc_info = XbmcInfo.new(outfile.path)
    new_xbmc_info.movie = @xbmc_info.movie
    new_xbmc_info.save
    verify_xbmc_info = XbmcInfo.new(outfile.path)
    verify_xbmc_info.movie.should == @xbmc_info.movie
  end

  it "verify .nfo file not overwritten if not changed" do
    false.should be_true
  end

  it "verify .nfo file is overwritten when changed" do
    false.should be_true
  end

end

describe "Profile finders" do

  before(:each) do
    logger = Log4r::Logger.new('dvdprofiler2xbmc')
    logger.outputters = Log4r::StdoutOutputter.new(:console)
    Log4r::Outputter[:console].formatter  = Log4r::PatternFormatter.new(:pattern => "%m")
    logger.level = Log4r::INFO
    AppConfig.default
    AppConfig[:logger] = logger
    AppConfig.load
#     @collection = Collection.new('spec/samples/Collection.xml')
    ImdbMovie.stub!(:use_html_cache).and_return(true)

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

  unless FULL_REGRESSION
    it "verify some titles (quick regression) find an IMDB ID using Imdb.first" do
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
    it "verify all Collection titles (full regression) find an IMDB ID using Imdb.first" do
#       buf = regression(@collection.title_isbn_hash.keys.sort)
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
