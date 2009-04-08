require File.dirname(__FILE__) + '/spec_helper.rb'

require 'tempfile'

# Time to add your specs!
# http://rspec.info/

describe "XbmcInfo" do

  before(:all) do
    logger = Log4r::Logger.new('dvdprofiler2xbmc')
    logger.outputters = Log4r::StdoutOutputter.new(:console)
    Log4r::Outputter[:console].formatter  = Log4r::PatternFormatter.new(:pattern => "%m")
    logger.level = Log4r::WARN
    AppConfig.default
    AppConfig[:logger] = logger
    AppConfig.load
    File.mkdirs(TMPDIR)
    AppConfig[:logger].warn { "\nXbmcInfo Specs" }
  end

  before(:each) do
    filespec = File.expand_path(File.join(File.dirname(__FILE__), 'samples/Die Hard - 1988.nfo'))
    @xbmc_info = XbmcInfo.new(filespec)
  end

  after(:all) do
    Dir.glob(File.join(TMPDIR,'xbmcinfo_*')).each { |filename| File.delete(filename) }
  end

  it "should load from the .nfo file" do
    @xbmc_info.movie['title'].first.should == 'Die Hard'
  end

  it "should create a .nfo file" do
    outfile = Tempfile.new('xbmcinfo_spec_create', TMPDIR)
    new_xbmc_info = XbmcInfo.new(outfile.path)
    new_xbmc_info.movie = @xbmc_info.movie
    new_xbmc_info.save
    (File.exist?(outfile.path).should be_true) && (File.size(outfile.path).should > 0)
  end

  it "should overwrite the .nfo file" do
    outfile = Tempfile.new('xbmcinfo_spec_overwrite', TMPDIR)
    new_xbmc_info = XbmcInfo.new(outfile.path)
    new_xbmc_info.movie = @xbmc_info.movie
    new_xbmc_info.save
    verify_xbmc_info = XbmcInfo.new(outfile.path)
    verify_xbmc_info.movie.should == @xbmc_info.movie
  end

  it "should not overwrite the .nfo file if not changed"

  it "should overwrite the .nfo file when changed"

  it "should be able to convert to xml and then from xml" do
    hash = nil
    begin
      xml = @xbmc_info.to_xml
      hash = XmlSimple.xml_in(xml)
    rescue
      hash = nil
    end
    hash.should_not be_nil
  end

end

