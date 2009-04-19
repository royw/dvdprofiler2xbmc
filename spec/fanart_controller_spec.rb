require File.dirname(__FILE__) + '/spec_helper.rb'

require 'tempfile'
require 'ruby-debug'

describe "FanartController" do

  before(:all) do
    logger = Log4r::Logger.new('dvdprofiler2xbmc')
    logger.outputters = Log4r::StdoutOutputter.new(:console)
    Log4r::Outputter[:console].formatter  = Log4r::PatternFormatter.new(:pattern => "%m")
    logger.level = Log4r::WARN
    AppConfig.default
    AppConfig[:logger] = logger
    AppConfig.load
    File.mkdirs(TMPDIR)
    AppConfig[:logger].warn { "\nFanartController Specs" }
  end

  before(:each) do
    Dir.glob(File.join(TMPDIR,'*-fanart*')).each { |filename| File.delete(filename) }
    Dir.glob(File.join(TMPDIR,'*.dummy')).each { |filename| File.delete(filename) }
    Dir.glob(File.join(TMPDIR,'*.tmdb.xml')).each { |filename| File.delete(filename) }

    FileUtils.touch(File.join(TMPDIR, 'Die Hard - 1988.dummy'))
    media = Media.new(TMPDIR, 'Die Hard - 1988.dummy')
    media.imdb_id = 'tt0095016'
    @controller = FanartController.new(media)
  end

  after(:all) do
    Dir.glob(File.join(TMPDIR,'*-fanart*')).each { |filename| File.delete(filename) }
    Dir.glob(File.join(TMPDIR,'*.dummy')).each { |filename| File.delete(filename) }
    Dir.glob(File.join(TMPDIR,'*.tmdb.xml')).each { |filename| File.delete(filename) }
  end

  it 'should generate "original.0" size destination filespec' do
    indexes = {}
    filespec = @controller.send('get_destination_filespec', '/tmp/movie title.m4v', 'original', indexes)
    filespec.should == "/tmp/movie title-fanart.original.0"
  end

  it 'should generate "mid.0" size destination filespec' do
    indexes = {}
    filespec = @controller.send('get_destination_filespec', '/tmp/movie title.m4v', 'mid', indexes)
    filespec.should == "/tmp/movie title-fanart.mid.0"
  end

  it 'should generate "thumb.0" size destination filespec' do
    indexes = {}
    filespec = @controller.send('get_destination_filespec', '/tmp/movie title.m4v', 'thumb', indexes)
    filespec.should == "/tmp/movie title-fanart.thumb.0"
  end

  it 'should generate "cover.0" size destination filespec' do
    indexes = {}
    filespec = @controller.send('get_destination_filespec', '/tmp/movie title.m4v', 'cover', indexes)
    filespec.should == "/tmp/movie title-fanart.cover.0"
  end

  it 'should generate "original.1" size destination filespec' do
    indexes = {'original' => 0}
    filespec = @controller.send('get_destination_filespec', '/tmp/movie title.m4v', 'original', indexes)
    filespec.should == "/tmp/movie title-fanart.original.1"
  end

  it 'should increment indexes' do
    indexes = {}
    filespec = @controller.send('get_destination_filespec', '/tmp/movie title.m4v', 'original', indexes)  # indexex['original'] => 0
    filespec = @controller.send('get_destination_filespec', '/tmp/movie title.m4v', 'original', indexes)  # indexex['original'] => 1
    filespec = @controller.send('get_destination_filespec', '/tmp/movie title.m4v', 'original', indexes)  # indexex['original'] => 2
    indexes['original'].should == 2 && filespec.should == "/tmp/movie title-fanart.original.2"
  end

  it 'should link to a fanart file' do
    dest_filespec = "#{TMPDIR}/foo-fanart"
    link_filespec = "#{dest_filespec}.jpg"
    touch("#{dest_filespec}.original.0.jpg")
    @controller.send('link_fanart', dest_filespec)
    File.exist?(link_filespec).should be_true
  end

  it 'should link to the first, largest (original) fanart file' do
    dest_filespec = "#{TMPDIR}/foo-fanart"
    link_filespec = "#{dest_filespec}.jpg"
    ['original', 'mid', 'thumb'].each do |size|
      0.upto(2) do |index|
        touch("#{dest_filespec}.#{size}.#{index}.jpg")
      end
    end
    @controller.send('link_fanart', dest_filespec)
    (File.exist?(link_filespec).should be_true) && (open(link_filespec).read.should == "#{dest_filespec}.original.0.jpg\n")
  end

  it 'should link to the first, largest (mid) fanart file' do
    dest_filespec = "#{TMPDIR}/foo-fanart"
    link_filespec = "#{dest_filespec}.jpg"
    ['mid', 'thumb'].each do |size|
      0.upto(2) do |index|
        touch("#{dest_filespec}.#{size}.#{index}.jpg")
      end
    end
    @controller.send('link_fanart', dest_filespec)
    (File.exist?(link_filespec).should be_true) && (open(link_filespec).read.should == "#{dest_filespec}.mid.0.jpg\n")
  end

  it 'should link to the first, largest (thumb) fanart file' do
    dest_filespec = "#{TMPDIR}/foo-fanart"
    link_filespec = "#{dest_filespec}.jpg"
    ['thumb'].each do |size|
      0.upto(2) do |index|
        touch("#{dest_filespec}.#{size}.#{index}.jpg")
      end
    end
    @controller.send('link_fanart', dest_filespec)
    (File.exist?(link_filespec).should be_true) && (open(link_filespec).read.should == "#{dest_filespec}.thumb.0.jpg\n")
  end

  it 'should fetch fanart' do
    @controller.send('fetch_fanart', 'tt0095016')
    buf = []
    %w(mid original thumb).each do |size|
      filespec = File.join(TMPDIR, "Die Hard - 1988-fanart.#{size}.0.jpg")
      buf << "Missing: \"#{filespec}\"" unless File.exist?(filespec) && (File.size(filespec) > 0)
    end
    puts buf.join("\n") unless buf.empty?
    buf.empty?.should be_true
  end

  it 'should fetch fanart with unicode characters in the URL' do
    buf = []
    titles = {'While You Were Sleeping' => 'tt0114924',
              'Sniper' => 'tt0108171',
              'Leon The Professional' => 'tt0110413'
             }
    titles.each do |title, imdb_id|
      FileUtils.touch(File.join(TMPDIR, "#{title}.dummy"))
      media = Media.new(TMPDIR, "#{title}.dummy")
      media.imdb_id = 'tt0095016'
      controller = FanartController.new(media)
      controller.send('fetch_fanart', imdb_id)
      %w(mid original thumb).each do |size|
        filespec = File.join(TMPDIR, "#{title}-fanart.#{size}.0.jpg")
        buf << filespec unless File.exist?(filespec) && (File.size(filespec) > 0)
      end
    end
    puts buf.join("\n") unless buf.empty?
    buf.empty?.should be_true
  end

  def touch(filespec)
    File.open(filespec, 'w') { |f| f.puts(filespec)}
  end
end
