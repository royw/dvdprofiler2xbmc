
# override the classes' read_page method and replace with one
# that will cache pages in spec/samples/{url}

module CacheExtensions
  # == Synopsis
  # Attach the read_page and cache_file methods to the given
  # class (cls) and use the given directory for the cache files
  def self.attach_to(cls, directory='/tmp')

    # define the read_page(page) method on the given class: cls
    cls.send('define_method', "read_page") do |page|
      data = nil
      filespec = page.gsub(/^http:\//, directory).gsub(/\/$/, '.html')
      if File.exist?(filespec)
        data = open(filespec).read
      else
        data = open(page).read
        cache_file(page, data)
      end
      data
    end

    # define the cache_file(page, data) method on the given class: cls
    cls.send('define_method', "cache_file") do |page, data|
      begin
        filespec = page.gsub(/^http:\//, directory).gsub(/\/$/, '.html')
        unless File.exist?(filespec)
          puts "caching #{filespec}"
          File.mkdirs(File.dirname(filespec))
          File.open(filespec, 'w') { |f| f.puts data }
        end
      rescue Exception => eMsg
        puts eMsg.to_s
      end
    end
  end

  # == Synopsis
  # Find all classes that have a read_page instance method and
  # then overwrite that read_page method with one that handles
  # the caching.  Use the given directory for the cache files.
  def self.attach_to_read_page_classes(directory='/tmp')
    ObjectSpace.each_object(Class) do |cls|
      if(cls.public_instance_methods(false).include?("read_page") ||
        cls.protected_instance_methods(false).include?("read_page") ||
        cls.private_instance_methods(false).include?("read_page"))
        CacheExtensions.attach_to(cls, directory)
      end
    end
  end
end

