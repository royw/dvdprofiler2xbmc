require File.dirname(__FILE__) + '/spec_helper.rb'

require File.dirname(__FILE__) + '/../lib/dvdprofiler2xbmc.rb'

FULL_REGRESSION = true

# Time to add your specs!
# http://rspec.info/
describe "IMDB lookup" do

  before(:each) do
    logger = Log4r::Logger.new('dvdprofiler2xbmc')
    logger.outputters = Log4r::StdoutOutputter.new(:console)
    Log4r::Outputter[:console].formatter  = Log4r::PatternFormatter.new(:pattern => "%m")
    logger.level = Log4r::INFO
    AppConfig.default
    AppConfig[:logger] = logger
    AppConfig.load
    @collection = Collection.new('spec/samples/Collection.xml')
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
          'Alexander the Great',
          'Anastasia',
          'About a Boy',
          'Gung Ho',
          'Hot Shots',
          'Meltdown',
          'Oklahoma!',
          'The Man From Snowy River',
          'Rooster Cogburn'
        ].collect{|title| Collection.title_pattern(title)}
      buf = regression(titles)
      buf.should be_empty
    end
  end

  if FULL_REGRESSION
    it "verify all Collection titles (full regression) find an IMDB ID using Imdb.first" do
      buf = regression(@collection.title_isbn_hash.keys.sort)
      buf.should be_empty
    end
  end

  def regression(titles)
    buf = []
    count = 0
    titles.each do |title|
      isbn = @collection.title_isbn_hash[title].flatten.uniq.compact.first
      unless @ignore_isbns.include?(isbn.to_s)
        dvd_hash = @collection.isbn_dvd_hash[isbn]
        unless dvd_hash[:genres].include?('Television')
          count += 1
          imdb = Imdb.new
          ident = imdb.first([dvd_hash[:title], title], [], dvd_hash[:productionyear], dvd_hash[:released])
          if ident.blank?
            buf << "Can not find IMDB ID for #{isbn} #{title}"
          end
        end
      end
    end
    puts buf.join("\n") + "\n\m# movies: #{count}\n# missing IMDB ID: #{buf.size}"
    buf
  end

end
