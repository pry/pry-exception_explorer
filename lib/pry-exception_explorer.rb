# pry-exception_explorer.rb
# (C) 2012 John Mair (banisterfiend); MIT license

require 'pry-stack_explorer'
require "pry-exception_explorer/version"
require "pry-exception_explorer/lazy_frame"
require "pry-exception_explorer/commands"
require "pry-exception_explorer/core_ext"

if RUBY_VERSION =~ /1.9/
  require 'continuation'
end

module PryExceptionExplorer

  # short-hand for `PryExceptionExplorer`
  ::EE = self

  # special constant
  CONTINUE_INLINE_EXCEPTION = Object.new

  class << self

    # @param [Boolean] v Whether Exception Explorer is enabled.
    def enabled=(v)
      Thread.current[:__pry_exception_explorer_enabled__] = v
    end

    # @return [Boolean] Whether Exception Explorer is enabled.
    def enabled
      !!Thread.current[:__pry_exception_explorer_enabled__]
    end

    # @param [Boolean] v Whether to intercept only those exceptions that bubble out of
    #   `EE.wrap` block.
    def wrap_active=(v)
      Thread.current[:__pry_exception_explorer_wrap__] = v
    end

    # @return [Boolean] Whether to intercept only those exceptions that bubble out of
    #   `EE.wrap` block.
    def wrap_active
      !!Thread.current[:__pry_exception_explorer_wrap__]
    end

    alias_method :wrap_active?, :wrap_active
    alias_method :enabled?, :enabled


    # Wrap the provided block - intercepting all exceptions
    # that bubble out, provided they satisfy the
    # assertion in `PryExceptionExplorer.intercept`.
    # @yield The block to wrap.
    def wrap
      old_enabled, old_wrap_active = enabled, wrap_active
      self.enabled     = true
      self.wrap_active = true
      yield
    rescue Exception => ex
      if ex.should_intercept?
        enter_exception(ex)
      else
        raise ex
      end
    ensure
      self.enabled     = old_enabled
      self.wrap_active = old_wrap_active
    end

    # This method allows the user to assert the situations where an
    # exception interception occurs.
    # This method can be invoked in two ways. The general form takes a
    # block, the block is passed both the frame where the exception was
    # raised, and the exception itself. The user then creates an
    # assertion (a stack-assertion)
    # based on these attributes. If the assertion is later satisfied by
    # a raised exception, that exception will be intercepted.
    # In the second form, the method simply takes an exception class, or
    # a number of exception classes. If one of these exceptions is
    # raised, it will be intercepted.
    # @param [Array] exceptions The exception classes that will be intercepted.
    # @yield [lazy_frame, exception] The block that determines whether an exception will be intercepted.
    # @yieldparam [PryExceptionExplorer::Lazyframe] frame The frame
    #   where the exception was raised.
    # @yieldparam [Exception] exception The exception that was raised.
    # @yieldreturn [Boolean] The result of the stack assertion.
    # @example First form: Assert method name is `toad` and exception is an `ArgumentError`
    #   PryExceptionExplorer.intercept do |frame, ex|
    #     frame.method_name == :toad && ex.is_a?(ArgumentError)
    #   end
    # @example Second form: Assert exception is either `ArgumentError` or `RuntimeError`
    #   PryExceptionExplorer.intercept(ArgumentError, RuntimeError)
    def intercept(*exceptions, &block)
      if !exceptions.empty?
        block = proc { |_, ex| exceptions.any? { |v| v === ex } }
      end

      Thread.current[:__pry_exception_explorer_intercept_block__] = block
    end

    # @return [Proc] The block defined earlier by a call to `PryExceptionExplorer.intercept`.
    def intercept_block
      Thread.current[:__pry_exception_explorer_intercept_block__]
    end

    # This method invokes the `PryExceptionExplorer.intercept_block`,
    # passing in the exception's frame and the exception object itself.
    # @param [Binding] frame The stack frame where the exception occurred.
    # @param [Exception] ex The exception that was raised.
    # @return [Boolean] Whether the exception should be intercepted.
    def should_intercept_exception?(frame, ex)
      if intercept_block
        intercept_block.call(LazyFrame.new(frame), ex)
      else
        false
      end
    end

    # Prepare the `Pry` instance and associated call-stack when entering
    # into an exception context.
    # @param [Exception] ex The exception.
    # @param [Pry] _pry_ The relevant `Pry` instance.
    # @param [Hash] options The optional configuration parameters.
    # @option options [Boolean] :inline Whether the exception is being
    #   entered inline (i.e within the `raise` method itself)
    def setup_exception_context(ex, _pry_, options={})
      _pry_.last_exception = ex
      _pry_.backtrace = ex.backtrace

      PryStackExplorer.frame_manager(_pry_).user[:exception]        = ex
      PryStackExplorer.frame_manager(_pry_).user[:inline_exception] = !!options[:inline]
    end

    # Enter the exception context.
    # @param [Exception] ex The exception.
    # @param [Hash] options The optional configuration parameters.
    # @option options [Boolean] :inline Whether the exception is being
    #   entered inline (i.e within the `raise` method itself)
    def enter_exception(ex, options={})
      hooks = Pry.config.hooks.dup.add_hook(:before_session, :set_exception_flag) do |_, _, _pry_|
        setup_exception_context(ex, _pry_, options)
      end

      Pry.start self, :call_stack => ex.exception_call_stack, :hooks => hooks
    end

    # Set initial state
    def init
      # disable by default (intercept exceptions inline)
      PryExceptionExplorer.wrap_active = false

      # default is to capture all exceptions
      PryExceptionExplorer.intercept { true }

      # disable by default
      PryExceptionExplorer.enabled = false
    end
  end
end

# Add a hook to enable EE when invoked via `pry` executable
Pry.config.hooks.add_hook(:when_started, :try_enable_exception_explorer) do
  if Pry.cli
    PryExceptionExplorer.wrap_active = true
    PryExceptionExplorer.enabled     = true
  end
end

# Bring in commands
Pry.config.commands.import PryExceptionExplorer::Commands

# Set initial state
PryExceptionExplorer.init


