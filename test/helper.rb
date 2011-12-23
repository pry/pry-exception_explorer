require 'rubygems'

unless Object.const_defined? 'PryExceptionExplorer'
  $:.unshift File.expand_path '../../lib', __FILE__
  require 'pry-exception_explorer'
end

require 'bacon'

puts "Testing pry-exception_explorer version #{PryExceptionExplorer::VERSION}..."
puts "Ruby version: #{RUBY_VERSION}"

EE = PryExceptionExplorer
