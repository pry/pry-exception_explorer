unless Object.const_defined? :PryExceptionExplorer
  $:.unshift File.expand_path '../../lib', __FILE__
  require 'pry'
end

require 'pry-exception_explorer'
require 'pry-exception_explorer/exception_wrap'

def alpha
  name = "john"
  beta
  puts name
end

def beta
  x = 20
  gamma
  puts x
end

def gamma
  raise "oh my, an exception"
end


PryExceptionExplorer.intercept(Exception)

PryExceptionExplorer.wrap do
  alpha
end
