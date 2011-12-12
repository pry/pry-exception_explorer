direc = File.dirname(__FILE__)

require 'rubygems'
require "#{direc}/../lib/pry-exception_explorer"
require 'bacon'

puts "Testing pry-exception_explorer version #{PryExceptionExplorer::VERSION}..." 
puts "Ruby version: #{RUBY_VERSION}"

describe PryExceptionExplorer do
end

