require File.dirname(__FILE__) + '/spec_helper.rb'

require 'tempfile'

# Time to add your specs!
# http://rspec.info/

describe "ImdbInfo" do

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

#   before(:each) do
#     filespec = File.expand_path(File.join(File.dirname(__FILE__), 'samples/Die Hard - 1988.nfo'))
#     @xbmc_info = XbmcInfo.new(filespec)
#   end
#
#   after(:all) do
#     Dir.glob(File.join(TMPDIR,'xbmcinfo_*')).each { |filename| File.delete(filename) }
#   end

  describe "Finder" do
    it "should find a profile" do
      info = ImdbInfo.find(:imdb_id => 'tt0465234')
      info.should_not be_nil
    end

    it "should return nil if profile not found" do
      info = ImdbInfo.find(:title => 'should not find this title')
      info.should be_nil
    end
  end

  describe "Attributes" do
    it "should generate xbmc_info" do
      info = ImdbInfo.find(:imdb_id => 'tt0465234')
      info.to_xbmc_info.length.should > 0
    end

    it "should generate valid xbmc_info" do
      info = ImdbInfo.find(:imdb_id => 'tt0465234')
      xbmc_info = info.to_xbmc_info
      xbmc_info['title'].should == "National Treasure: Book of Secrets"
    end

    it "should return imdb id when profile has one" do
      info = ImdbInfo.find(:imdb_id => 'tt0465234')
      info.imdb_id.should == 'tt0465234'
    end
  end

end

