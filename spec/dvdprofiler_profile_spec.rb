require File.dirname(__FILE__) + '/spec_helper.rb'

require 'tempfile'

# Time to add your specs!
# http://rspec.info/

describe "DvdprofilerProfile" do

  before(:all) do
#     logger = Log4r::Logger.new('dvdprofiler2xbmc')
#     logger.outputters = Log4r::StdoutOutputter.new(:console)
#     Log4r::Outputter[:console].formatter  = Log4r::PatternFormatter.new(:pattern => "%m")
#     logger.level = Log4r::WARN
#     AppConfig.default
#     AppConfig[:logger] = logger
#     AppConfig.load
#     AppConfig[:collection_filespec] = 'spec/samples/Collection.xml'
    File.mkdirs(TMPDIR)
#     AppConfig[:logger].warn { "\nDvdprofilerProfile Specs" }
    puts "\nDvdprofilerProfile Specs"
  end

  before(:each) do
    DvdprofilerProfile.collection_filespec = 'spec/samples/Collection.xml'
    @profile = DvdprofilerProfile.first(:isbn => '786936735390')
  end

  after(:all) do
    Dir.glob(File.join(TMPDIR, "dvdprofiler_profile_spec*")).each { |filename| File.delete(filename) }
  end

  it "should find by imdb_id" do
    @profile.should_not == nil
  end

  it "should find by title" do
    profile = DvdprofilerProfile.first(:title => 'National Treasure 2: Book of Secrets')
    profile.should_not == nil
  end

  it "should find find by fuzzy title" do
    profile = DvdprofilerProfile.first(:title => 'National Treasure 2 Book of Secrets')
    profile.should_not == nil
  end

  it "should find by case insensitive title" do
    profile = DvdprofilerProfile.first(:title => 'national treasure 2: book of secrets')
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

  it "should find multiple movies with the same title" do
    profiles = DvdprofilerProfile.all(:title => 'Sabrina')
    profiles.length.should == 2
  end

  it "should find a single movie using the year when multiple movies have the same title" do
    profiles = DvdprofilerProfile.all(:title => 'Sabrina', :year => '1995')
    (profiles.length.should == 1) && (profiles.first.isbn.should == '097363304340')
  end

  it "should find the other single movie using the year when multiple movies have the same title" do
    profiles = DvdprofilerProfile.all(:title => 'Sabrina', :year => '1954')
    (profiles.length.should == 1) && (profiles.first.isbn.should == '097360540246')
  end

end