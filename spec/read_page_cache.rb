# == Synopsis
# The purpose of the module is to cache web pages used for
# testing by overriding the classes' read_page method and
# replacing it with one that will cache pages.
#
# == Usage
# Your main code needs to have a read_page(page) instance
# method(s).  Here's an example:
#
#   class ClassName
#     def read_page(page)
#       open(page).read
#     end
#   end
#
# Then your test code should include:
#
#   # default directory is '/tmp'
#   directory = '/path/to/cache/files'
#   require 'cache_extensions'
#   ReadPageCache.attach_to ClassName, directory
#
# You may attach_to however many classes that you need to.
#
# If you want to override all the read_page(page) methods
# in your application, then your test code can instead use:
#
#   # default directory is '/tmp'
#   directory = '/path/to/cache/files'
#   require 'cache_extensions'
#   ReadPageCache.attach_to_classes directory
#
# That's it.  The first time you run your tests, the pages
# your application accesses with read_page will be cached,
# then the cached files will be used by all subsequent accesses.
#
module ReadPageCache
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
        _cache_file(page, data)
      end
      data
    end

    # define the cache_file(page, data) method on the given class: cls
    cls.send('define_method', "_cache_file") do |page, data|
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
  def self.attach_to_classes(directory='/tmp')
    ObjectSpace.each_object(Class) do |cls|
      # need to check all scopes for read_page instance method
      if(cls.public_instance_methods(false).include?("read_page") ||
        cls.protected_instance_methods(false).include?("read_page") ||
        cls.private_instance_methods(false).include?("read_page"))
        ReadPageCache.attach_to(cls, directory)
      end
    end
  end
end

