$:.unshift 'lib'

dlext = RbConfig::CONFIG['DLEXT']
direc = File.dirname(__FILE__)
PROJECT_NAME = "pry-exception_explorer"
$VERBOSE = nil

require 'rake/clean'
require 'rake/gempackagetask'
require "#{PROJECT_NAME}/version"

CLOBBER.include("**/*~", "**/*#*", "**/*.log")
CLEAN.include("**/*#*", "**/*#*.*", "**/*_flymake*.*", "**/*_flymake",
              "**/*.rbc", "**/.#*.*")

def apply_spec_defaults(s)
  s.name = PROJECT_NAME
  s.summary = "Enter the context of exceptions"
  s.version = PryExceptionExplorer::VERSION
  s.date = Time.now.strftime '%Y-%m-%d'
  s.author = "John Mair (banisterfiend)"
  s.email = 'jrmair@gmail.com'
  s.description = s.summary
  s.require_path = 'lib'
  s.homepage = "https://github.com/banister/pry-exception_explorer"
  s.add_dependency('pry-stack_explorer', ">=0.4.6")
  s.add_development_dependency("bacon","~>1.1.0")
  s.add_development_dependency('rake', '~> 0.9')

  s.files = `git ls-files`.split("\n")
  s.test_files = `git ls-files -- test/*`.split("\n")
end

desc "run pry with plugin enabled"
task :pry do
  exec("pry -I#{direc}/lib/ -r #{direc}/lib/#{PROJECT_NAME}")
end

desc "reinstall gem"
task :reinstall => :gems do
  sh "rm -rf ~/.pry-exception_explorer"
  sh "gem uninstall pry-exception_explorer" rescue nil
  sh "gem install #{direc}/pkg/pry-exception_explorer-#{PryExceptionExplorer::VERSION}.gem"
end

desc "Run example wrap"
task :example_wrap do
  sh "ruby -I#{direc}/lib/ #{direc}/examples/example_wrap.rb "
end

desc "Run example inline"
task :example_inline do
  sh "ruby -I#{direc}/lib/ #{direc}/examples/example_inline.rb "
end

desc "Run example C inline"
task :example_c_inline do
  sh "ruby -I#{direc}/lib/ #{direc}/examples/example_c_inline.rb "
end

desc "Run example C wrap"
task :example_c_wrap do
  sh "ruby -I#{direc}/lib/ #{direc}/examples/example_c_wrap.rb "
end

desc "Run example post mortem"
task :example_post_mortem do
  sh "ruby -I#{direc}/lib/ #{direc}/examples/example_post_mortem.rb "
end

task :default => :test

desc "Show version"
task :version do
  puts "PryExceptionExplorer version: #{PryExceptionExplorer::VERSION}"
end

desc "run tests"
task :test do
 sh "bacon -Itest -rubygems -a -q"
end

desc "Build gemspec"
task :gemspec => "ruby:gemspec"

namespace :ruby do
  spec = Gem::Specification.new do |s|
    apply_spec_defaults(s)
    s.platform = Gem::Platform::RUBY
  end

  Rake::GemPackageTask.new(spec) do |pkg|
    pkg.need_zip = false
    pkg.need_tar = false
  end

  desc  "Generate gemspec file"
  task :gemspec do
    File.open("#{spec.name}.gemspec", "w") do |f|
      f << spec.to_ruby
    end
  end
end

desc "shorthand for :gems task"
task :gem => :gems

desc "build all platform gems at once"
task :gems => [:clean, :rmgems, "ruby:gem"]

desc "remove all platform gems"
task :rmgems => ["ruby:clobber_package"]

desc "build and push latest gems"
task :pushgems => :gems do
  chdir("#{File.dirname(__FILE__)}/pkg") do
    Dir["*.gem"].each do |gemfile|
      sh "gem push #{gemfile}"
    end
  end
end


