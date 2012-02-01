# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = %q{pry-exception_explorer}
  s.version = "0.1.3"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = [%q{John Mair (banisterfiend)}]
  s.date = %q{2012-02-02}
  s.description = %q{Enter the context of exceptions}
  s.email = %q{jrmair@gmail.com}
  s.files = [%q{.gemtest}, %q{.gitignore}, %q{.travis.yml}, %q{.yardopts}, %q{CHANGELOG}, %q{Gemfile}, %q{LICENSE}, %q{README.md}, %q{Rakefile}, %q{examples/example_c_inline.rb}, %q{examples/example_inline.rb}, %q{examples/example_wrap.rb}, %q{lib/pry-exception_explorer.rb}, %q{lib/pry-exception_explorer/cli.rb}, %q{lib/pry-exception_explorer/commands.rb}, %q{lib/pry-exception_explorer/core_ext.rb}, %q{lib/pry-exception_explorer/intercept.rb}, %q{lib/pry-exception_explorer/lazy_frame.rb}, %q{lib/pry-exception_explorer/shim_builder.rb}, %q{lib/pry-exception_explorer/version.rb}, %q{pry-exception_explorer.gemspec}, %q{test/helper.rb}, %q{test/test_exceptions_in_pry.rb}, %q{test/test_inline_exceptions.rb}, %q{test/test_wrapped_exceptions.rb}]
  s.homepage = %q{https://github.com/banister/pry-exception_explorer}
  s.require_paths = [%q{lib}]
  s.rubygems_version = %q{1.8.6}
  s.summary = %q{Enter the context of exceptions}
  s.test_files = [%q{test/helper.rb}, %q{test/test_exceptions_in_pry.rb}, %q{test/test_inline_exceptions.rb}, %q{test/test_wrapped_exceptions.rb}]

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
