require File.dirname(__FILE__) + '/spec_helper.rb'

require 'tempfile'

# Time to add your specs!
# http://rspec.info/

describe "DvdprofilerInfo" do

  before(:all) do
    logger = Log4r::Logger.new('dvdprofiler2xbmc')
    logger.outputters = Log4r::StdoutOutputter.new(:console)
    Log4r::Outputter[:console].formatter  = Log4r::PatternFormatter.new(:pattern => "%m")
    logger.level = Log4r::WARN
    AppConfig.default
    AppConfig[:logger] = logger
    AppConfig.load
    File.mkdirs(TMPDIR)
    DvdprofilerProfile.collection_filespec = File.join(SAMPLES_DIR, 'Collection.xml')
  end

  describe "Finder" do
    it "should find a profile" do

      info = DvdprofilerInfo.find(:isbn => '786936735390')
      info.should_not be_nil
    end

    it "should return nil if profile not found" do
      info = DvdprofilerInfo.find(:title => 'should not find this title')
      info.should be_nil
    end
  end

  describe "Attributes" do
    it "should generate xbmc_info" do
      info = DvdprofilerInfo.find(:isbn => '786936735390')
      info.to_xbmc_info.length.should > 0
    end

    it "should generate valid xbmc_info" do
      info = DvdprofilerInfo.find(:isbn => '786936735390')
      xbmc_info = info.to_xbmc_info
      xbmc_info['title'].should == "National Treasure 2: Book of Secrets"
    end

    it "should return ISBN when profile has one" do
      info = DvdprofilerInfo.find(:isbn => '786936735390')
      info.isbn.should == '786936735390'
    end

    it "should return lowest production year for the media" do
      info = DvdprofilerInfo.find(:isbn => '786936735390')
      info.year.should == '2007'
    end

    it "should return box_set_parent_titles" do
      info = DvdprofilerInfo.find(:title => ' The Scorpion King')
      info.box_set_parent_titles.should == ["The Mummy Collector's Set"]
    end

    it "should return production_years" do
      info = DvdprofilerInfo.find(:isbn => '786936735390')
      info.production_years.should == ['2007']
    end

    it "should return released_years" do
      info = DvdprofilerInfo.find(:isbn => '786936735390')
      info.released_years.should == ['2008']
    end

    it "should return original_titles" do
      info = DvdprofilerInfo.find(:isbn => '786936735390')
      info.original_titles.should == ["National Treasure: Book of Secrets"]
    end

    it "should return title" do
      info = DvdprofilerInfo.find(:isbn => '786936735390')
      info.title.should == "National Treasure 2: Book of Secrets"
    end

  end

end

