%w[rubygems rake rake/clean fileutils newgem rubigen].each { |f| require f }
require File.dirname(__FILE__) + '/lib/dvdprofiler2xbmc'

# Generate all the Rake tasks
# Run 'rake -T' to see list of generated tasks (from gem root directory)
$hoe = Hoe.new('dvdprofiler2xbmc', Dvdprofiler2xbmc::VERSION) do |p|
  p.developer('Roy Wright', 'roy@wright.org')
  p.changes              = p.paragraphs_of("History.txt", 0..1).join("\n\n")
  p.post_install_message = 'PostInstall.txt' # TODO remove if post-install message not required
  p.rubyforge_name       = p.name # TODO this is default value
  p.extra_deps         = [
    ['activesupport','>= 2.0.2'],
    ['xml-simple','>= 1.0.12'],
    ['royw-imdb','>= 0.0.16'],
    ['log4r','>= 1.0.5'],
    ['commandline','>= 0.7.10'],
    ['mash','>= 0.0.3'],
    ['highline', '>= 1.5.0']
  ]
  p.extra_dev_deps = [
    ['newgem', ">= #{::Newgem::VERSION}"]
  ]

  p.clean_globs |= %w[**/.DS_Store tmp *.log]
  path = (p.rubyforge_name == p.name) ? p.rubyforge_name : "\#{p.rubyforge_name}/\#{p.name}"
  p.remote_rdoc_dir = File.join(path.gsub(/^#{p.rubyforge_name}\/?/,''), 'rdoc')
  p.rsync_args = '-av --delete --ignore-errors'
end

require 'newgem/tasks' # load /tasks/*.rake
Dir['tasks/**/*.rake'].each { |t| load t }

# TODO - want other tests/tasks run by default? Add them to the list
# task :default => [:spec, :features]
