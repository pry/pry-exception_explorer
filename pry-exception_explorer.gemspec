# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = "pry-exception_explorer"
  s.version = "0.1.1pre2"

  s.required_rubygems_version = Gem::Requirement.new("> 1.3.1") if s.respond_to? :required_rubygems_version=
  s.authors = ["John Mair (banisterfiend)"]
  s.date = "2011-12-23"
  s.description = "Enter the context of exceptions"
  s.email = "jrmair@gmail.com"
  s.files = [".gemtest", ".gitignore", ".yardopts", "CHANGELOG", "Gemfile", "LICENSE", "README.md", "Rakefile", "lib/pry-exception_explorer.rb", "lib/pry-exception_explorer/cli.rb", "lib/pry-exception_explorer/commands.rb", "lib/pry-exception_explorer/exception_wrap.rb", "lib/pry-exception_explorer/lazy_frame.rb", "lib/pry-exception_explorer/shim_builder.rb", "lib/pry-exception_explorer/version.rb", "test/helper.rb", "test/test_exception_explorer.rb"]
  s.homepage = "https://github.com/banister/pry-exception_explorer"
  s.require_paths = ["lib"]
  s.rubygems_version = "1.8.11"
  s.summary = "Enter the context of exceptions"
  s.test_files = ["test/helper.rb", "test/test_exception_explorer.rb"]

  if s.respond_to? :specification_version then
    s.specification_version = 3

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<pry-stack_explorer>, [">= 0"])
      s.add_development_dependency(%q<bacon>, ["~> 1.1.0"])
      s.add_development_dependency(%q<rake>, ["~> 0.9"])
    else
      s.add_dependency(%q<pry-stack_explorer>, [">= 0"])
      s.add_dependency(%q<bacon>, ["~> 1.1.0"])
      s.add_dependency(%q<rake>, ["~> 0.9"])
    end
  else
    s.add_dependency(%q<pry-stack_explorer>, [">= 0"])
    s.add_dependency(%q<bacon>, ["~> 1.1.0"])
    s.add_dependency(%q<rake>, ["~> 0.9"])
  end
end
