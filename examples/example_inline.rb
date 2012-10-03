unless Object.const_defined? :PryExceptionExplorer
  $:.unshift File.expand_path '../../lib', __FILE__
  require 'pry'
end

require 'pry-exception_explorer'

EE.inline!
PryExceptionExplorer.intercept(ArgumentError)

def alpha
  name = "john"
  beta
  puts name
end

def beta
  x = "john"
  gamma(x)
end

def gamma(x)
  raise ArgumentError, "x must be a number!" if !x.is_a?(Numeric)
  puts "2 * x = #{2 * x}"
end

alpha
