# pry-exception_explorer.rb
# (C) John Mair (banisterfiend); MIT license

require 'pry-stack_explorer'
require "pry-exception_explorer/version"
require "pry-exception_explorer/lazy_frame"
require "pry-exception_explorer/commands"
require "pry"

if RUBY_VERSION =~ /1.9/
  require 'continuation'
end

module PryExceptionExplorer
  CONTINUE_INLINE_EXCEPTION = Object.new

  class << self
    def wrap_active=(v)
      Thread.current[:__pry_exception_explorer_wrap__] = v
    end

    def wrap_active
      !!Thread.current[:__pry_exception_explorer_wrap__]
    end

    alias_method :wrap_active?, :wrap_active
  end

  self.wrap_active = false

  def self.should_capture_exception?(ex)
    true
  end

  def self.intercept(&block)
    Thread.current[:__pry_exception_explorer_intercept_block__] = block
  end

  def self.intercept_block
    Thread.current[:__pry_exception_explorer_intercept_block__]
  end

  def self.should_capture_exception?(ex, frame)
    if intercept_block
      intercept_block.call(LazyFrame.new(frame), ex)
    else
      false
    end
  end

  def self.enter_exception_inline(ex)
    _pry_ = Pry.new

    Pry.initial_session_setup
    PryStackExplorer.create_and_push_frame_manager(ex.exception_call_stack, _pry_)
    PryStackExplorer.frame_manager(_pry_).user[:exception]        = ex
    PryStackExplorer.frame_manager(_pry_).user[:inline_exception] = true
    _pry_.repl(ex.exception_call_stack.first)

  ensure
    PryStackExplorer.clear_frame_managers(_pry_)
  end
end

class Exception
  NoContinuation = Class.new(StandardError)

  attr_accessor :continuation
  attr_accessor :exception_call_stack
  attr_accessor :should_capture

  def continue
    raise NoContinuation unless continuation.respond_to?(:call)
    continuation.call
  end

  alias_method :should_capture?, :should_capture
end

class Object
  def raise(exception = RuntimeError, string = nil, array = caller)
    if exception.is_a?(String)
      string = exception
      exception = RuntimeError
    end

    ex = exception.exception(string)
    ex.set_backtrace(array)

    if PryExceptionExplorer.should_capture_exception?(ex, binding.of_caller(1))
      ex.exception_call_stack = binding.callers.tap(&:shift)
      ex.should_capture       = true

      if !PryExceptionExplorer.wrap_active?
        retval = PryExceptionExplorer.enter_exception_inline(ex)
      end
    end

    if retval != PryExceptionExplorer::CONTINUE_INLINE_EXCEPTION
      callcc do |cc|
        ex.continuation = cc
        super(ex)
      end
    end
  end
end


# Let exceptions get caught by Pry REPL loop (i.e dont catch
# immediately at point of 'raise')
PryExceptionExplorer.wrap_active = true

# default is to capture all exceptions that bubble to the top
PryExceptionExplorer.intercept { true }

Pry.config.commands.import PryExceptionExplorer::Commands
