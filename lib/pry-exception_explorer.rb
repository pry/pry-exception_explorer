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

    def enabled=(v)
      Thread.current[:__pry_exception_explorer_enabled__] = v
    end

    def enabled
      !!Thread.current[:__pry_exception_explorer_enabled__]
    end

    def wrap_active
      !!Thread.current[:__pry_exception_explorer_wrap__]
    end

    def wrap_active=(v)
      Thread.current[:__pry_exception_explorer_wrap__] = v
    end

    def wrap_active
      !!Thread.current[:__pry_exception_explorer_wrap__]
    end

    alias_method :wrap_active?, :wrap_active
    alias_method :enabled?, :enabled
  end

  self.wrap_active = false

  def self.should_capture_exception?(ex)
    true
  end

  def self.intercept(*exceptions, &block)
    if !exceptions.empty?
      block = proc { |_, ex| exceptions.any? { |v| v === ex } }
    end

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

  def self.setup_exception_context(ex, _pry_, options={})
    _pry_.last_exception = ex
    _pry_.backtrace = ex.backtrace

    PryStackExplorer.frame_manager(_pry_).user[:exception]        = ex
    PryStackExplorer.frame_manager(_pry_).user[:inline_exception] = !!options[:inline]
  end

  def self.enter_exception(ex, options={})
    hooks = Pry.config.hooks.dup.add_hook(:before_session, :set_exception_flag) do |_, _, _pry_|

      setup_exception_context(ex, _pry_, options)
    end

    Pry.start self, :call_stack => ex.exception_call_stack, :hooks => hooks
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

    # revert to normal exception behaviour if EE not enabled.
    if !PryExceptionExplorer.enabled?
      return super(ex)
    end

    if PryExceptionExplorer.should_capture_exception?(ex, binding.of_caller(1))
      ex.exception_call_stack = binding.callers.tap(&:shift)
      ex.should_capture       = true

      if !PryExceptionExplorer.wrap_active?
        retval = PryExceptionExplorer.enter_exception(ex, :inline => true)
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

#
PryExceptionExplorer.wrap_active = false

# default is to capture all exceptions that bubble to the top
PryExceptionExplorer.intercept { true }

Pry.config.commands.import PryExceptionExplorer::Commands

# disable by default
PryExceptionExplorer.enabled = false

Pry.config.hooks.add_hook(:when_started, :try_enable_exception_explorer) do
  if Pry.cli
    PryExceptionExplorer.wrap_active = true
    PryExceptionExplorer.enabled     = true
  end
end
