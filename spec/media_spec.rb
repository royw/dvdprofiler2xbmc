require File.dirname(__FILE__) + '/spec_helper.rb'

require 'tempfile'

describe "Media" do

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

  describe "Media filename parsing" do
    # "movie title - yyyy.ext"
    # "movie title (yyyy).ext"
    # "movie title.ext"
    # "movie title - yyyy.partN.ext"
    # "movie title (yyyy).partN.ext"
    # "movie title.partN.ext"

    it 'should parse "movie title.m4v"' do
      result = Media.parse('movie title.m4v')
      result.should == {:title => 'movie title', :extension => 'm4v'}
    end

    it 'should parse "movie title - 1999.m4v"' do
      result = Media.parse('movie title - 1999.m4v')
      result.should == {:title => 'movie title', :year => '1999', :extension => 'm4v'}
    end

    it 'should parse "movie title-1999.m4v"' do
      result = Media.parse('movie title-1999.m4v')
      result.should == {:title => 'movie title', :year => '1999', :extension => 'm4v'}
    end

    it 'should parse "movie title (1999).m4v"' do
      result = Media.parse('movie title (1999).m4v')
      result.should == {:title => 'movie title', :year => '1999', :extension => 'm4v'}
    end

    it 'should parse "movie title ( 1999 ) .m4v"' do
      result = Media.parse('movie title ( 1999 ) .m4v')
      result.should == {:title => 'movie title', :year => '1999', :extension => 'm4v'}
    end

    it 'should parse "movie title.cd1.m4v"' do
      result = Media.parse('movie title.cd1.m4v')
      result.should == {:title => 'movie title', :part => 'cd1', :extension => 'm4v'}
    end

    it 'should parse "movie title - 1999.cd1.m4v"' do
      result = Media.parse('movie title - 1999.cd1.m4v')
      result.should == {:title => 'movie title', :year => '1999', :part => 'cd1', :extension => 'm4v'}
    end

    it 'should parse "movie title-1999.cd1.m4v"' do
      result = Media.parse('movie title-1999.cd1.m4v')
      result.should == {:title => 'movie title', :year => '1999', :part => 'cd1', :extension => 'm4v'}
    end

    it 'should parse "movie title (1999).cd1.m4v"' do
      result = Media.parse('movie title (1999).cd1.m4v')
      result.should == {:title => 'movie title', :year => '1999', :part => 'cd1', :extension => 'm4v'}
    end

    it 'should parse "movie title ( 1999 ) .cd1.m4v"' do
      result = Media.parse('movie title ( 1999 ) .cd1.m4v')
      result.should == {:title => 'movie title', :year => '1999', :part => 'cd1', :extension => 'm4v'}
    end
  end

  describe "NFO filename generation" do
    it 'should generate path_to(:nfo)' do
      media = Media.new(File.join(File.dirname(__FILE__), 'samples'), 'The Egg and I.dummy')
      media.path_to(:nfo).should == File.expand_path('spec/samples/The Egg and I.nfo')
    end

    it 'should generate path_to(:nfo) for multipart media' do
      media = Media.new(File.join(File.dirname(__FILE__), 'samples'), 'Ma and Pa Kettle.cd1.dummy')
      media.path_to(:nfo).should == File.expand_path('spec/samples/Ma and Pa Kettle.nfo')
    end
  end

end
