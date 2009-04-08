# NOTE extremely ugly and non-DRY.  Probably good candidate for meta programming.

# override the classes' read_page method and replace with one
# that will cache pages in spec/samples/{url}

class TmdbMovie
  private
  def read_page(page)
    html = nil
    filespec = page.gsub(/^http:\//, 'spec/samples').gsub(/\/$/, '.html')
    if File.exist?(filespec)
      html = open(filespec).read
    else
      html = open(page).read
      cache_html_files(page, html)
    end
    html
  end

  # this is used to save imdb pages so they may be used by rspec
  def cache_html_files(page, html)
    begin
      filespec = page.gsub(/^http:\//, 'spec/samples').gsub(/\/$/, '.html')
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

class ImdbMovie
  private
  def read_page(page)
    html = nil
    filespec = page.gsub(/^http:\//, 'spec/samples').gsub(/\/$/, '.html')
    if File.exist?(filespec)
      html = open(filespec).read
    else
      html = open(page).read
      cache_html_files(page, html)
    end
    html
  end

  # this is used to save imdb pages so they may be used by rspec
  def cache_html_files(page, html)
    begin
      filespec = page.gsub(/^http:\//, 'spec/samples').gsub(/\/$/, '.html')
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

class ImdbSearch
  private
  def read_page(page)
    html = nil
    filespec = page.gsub(/^http:\//, 'spec/samples').gsub(/\/$/, '.html')
    if File.exist?(filespec)
      html = open(filespec).read
    else
      html = open(page).read
      cache_html_files(page, html)
    end
    html
  end

  # this is used to save imdb pages so they may be used by rspec
  def cache_html_files(page, html)
    begin
      filespec = page.gsub(/^http:\//, 'spec/samples').gsub(/\/$/, '.html')
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

class ImdbImage
  private
  def read_page(page)
    html = nil
    filespec = page.gsub(/^http:\//, 'spec/samples').gsub(/\/$/, '.html')
    if File.exist?(filespec)
      html = open(filespec).read
    else
      html = open(page).read
      cache_html_files(page, html)
    end
    html
  end

  # this is used to save imdb pages so they may be used by rspec
  def cache_html_files(page, html)
    begin
      filespec = page.gsub(/^http:\//, 'spec/samples').gsub(/\/$/, '.html')
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
