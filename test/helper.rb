require 'rubygems'

unless Object.const_defined? 'PryExceptionExplorer'
  $:.unshift File.expand_path '../../lib', __FILE__
  require 'pry-exception_explorer'
end

require 'bacon'

puts "Testing pry-exception_explorer version #{PryExceptionExplorer::VERSION}..."
puts "Ruby version: #{RUBY_VERSION}"

EE = PryExceptionExplorer

# override enter_exception_inline so we can use it for testing purposes
EE.instance_eval do
  alias original_enter_exception_inline enter_exception_inline
end

def EE.exception_intercepted?
  @exception_intercepted
end

EE.instance_eval do
  @exception_intercepted = false
end

def EE.enter_exception_inline(ex)
  @exception_intercepted = true
  EE::CONTINUE_INLINE_EXCEPTION
end

class Ratty
  def ratty
    Weasel.new.weasel
  end
end

class Weasel
  def weasel
    Toad.new.toad
  end
end

class Toad
  def toad
    raise "toad hall"
  end
end
