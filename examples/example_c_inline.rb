unless Object.const_defined? :PryExceptionExplorer
  $:.unshift File.expand_path '../../lib', __FILE__
  require 'pry'
end

require 'pry-exception_explorer'

EE.inline!

# we need to fine tune intercept when intercepting C exceptions
# otherwise we could be intercepting exceptions internal to rubygems
# and god knows what else...
EE.intercept(ZeroDivisionError)

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
  1/0
end

alpha
