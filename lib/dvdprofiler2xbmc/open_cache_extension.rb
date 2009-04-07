
#
class Kernel
  attr_accessor :html_cache_dir
  @html_cache_dir = '/tmp'

  # cache any files read using http protocol
  def open_cache(url)
    if url =~ /^https?:\/\//i
      filespec = url.gsub(/^http:\//, @html_cache_dir).gsub(/\/$/, '.html')
      begin
        fh = open(filespec)
      rescue Exception
        fh = open(url)
        cache_html_files(filespec, fh.read)
        fh.rewind
      end
    else
      fh = open(url)
    end
    fh
  end

  private

  # this is used to save imdb pages so they may be used by rspec
  def cache_html_files(filespec, html)
    begin
      unless File.exist?(filespec)
        puts "caching #{filespec}"
        File.mkdirs(File.dirname(filespec))
        File.open(filespec, 'w') { |f| f.puts html }
      end
    rescue Exception => eMsg
      puts eMsg.to_s
    end
  end

end
