require File.dirname(__FILE__) + '/spec_helper.rb'

require 'tempfile'

# Time to add your specs!
# http://rspec.info/

describe "TmdbInfo" do

  before(:all) do
    logger = Log4r::Logger.new('dvdprofiler2xbmc')
    logger.outputters = Log4r::StdoutOutputter.new(:console)
    Log4r::Outputter[:console].formatter  = Log4r::PatternFormatter.new(:pattern => "%m")
    logger.level = Log4r::WARN
    AppConfig.default
    AppConfig[:logger] = logger
    AppConfig.load
    File.mkdirs(TMPDIR)
  end

  describe "Finder" do
    it "should find a profile" do
      info = TmdbInfo.find(:imdb_id => 'tt0465234', :api_key => TMDB_API_KEY, :filespec => nil)
      info.should_not be_nil
    end

    it "should return nil if profile not found" do
      info = TmdbInfo.find(:title => 'should not find this title', :api_key => TMDB_API_KEY, :filespec => nil)
      info.should be_nil
    end
  end

  describe "Attributes" do
    it "should generate xbmc_info" do
      info = TmdbInfo.find(:imdb_id => 'tt0465234', :api_key => TMDB_API_KEY, :filespec => nil)
      info.to_xbmc_info.length.should > 0
    end

    it "should generate valid xbmc_info" do
      info = TmdbInfo.find(:imdb_id => 'tt0465234', :api_key => TMDB_API_KEY, :filespec => nil)
      xbmc_info = info.to_xbmc_info
      xbmc_info['plot'].should =~ /^Treasure hunter/
    end
  end

end

