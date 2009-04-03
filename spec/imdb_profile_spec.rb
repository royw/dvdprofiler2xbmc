require File.dirname(__FILE__) + '/spec_helper.rb'

require 'tempfile'

# Time to add your specs!
# http://rspec.info/

describe "ImdbProfile" do

  before(:all) do
    logger = Log4r::Logger.new('dvdprofiler2xbmc')
    logger.outputters = Log4r::StdoutOutputter.new(:console)
    Log4r::Outputter[:console].formatter  = Log4r::PatternFormatter.new(:pattern => "%m")
    logger.level = Log4r::INFO
    AppConfig.default
    AppConfig[:logger] = logger
    AppConfig.load
  end

  before(:each) do
    @profile = ImdbProfile.first(:imdb_id => 'tt0465234')
  end

  after(:all) do
    Dir.glob(File.join(TMPDIR, "imdb_profile_spec*")).each { |filename| File.delete(filename) }
  end

  it "should find by imdb_id" do
    @profile.should_not == nil
  end

  it "should find by imdb_id that is not prefixed with 'tt'" do
    profile = ImdbProfile.first(:imdb_id => '0465234')
    profile.should_not == nil
  end

  it "should find by title" do
    profile = ImdbProfile.first(:titles => ['National Treasure: Book of Secrets'])
    profile.should_not == nil
  end

end