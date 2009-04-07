require File.dirname(__FILE__) + '/spec_helper.rb'

require 'tempfile'

# Time to add your specs!
# http://rspec.info/

describe "DvdprofilerProfile" do

  before(:all) do
    logger = Log4r::Logger.new('dvdprofiler2xbmc')
    logger.outputters = Log4r::StdoutOutputter.new(:console)
    Log4r::Outputter[:console].formatter  = Log4r::PatternFormatter.new(:pattern => "%m")
    logger.level = Log4r::INFO
    AppConfig.default
    AppConfig[:logger] = logger
    AppConfig.load
    AppConfig[:collection_filespec] = 'spec/samples/Collection.xml'
    File.mkdirs(TMPDIR)
  end

  before(:each) do
    @profile = DvdprofilerProfile.first(:isbn => '786936735390')
  end

  after(:all) do
    Dir.glob(File.join(TMPDIR, "dvdprofiler_profile_spec*")).each { |filename| File.delete(filename) }
  end

  it "should find by imdb_id" do
    @profile.should_not == nil
  end

  it "should find by title" do
    profile = DvdprofilerProfile.first(:titles => ['National Treasure: Book of Secrets'])
    profile.should_not == nil
  end

  it "should be able to convert to xml and then from xml" do
    hash = nil
    begin
      xml = @profile.to_xml
      hash = XmlSimple.xml_in(xml)
    rescue
      hash = nil
    end
    hash.should_not be_nil
  end

end