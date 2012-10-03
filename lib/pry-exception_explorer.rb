# pry-exception_explorer.rb
# (C) 2012 John Mair (banisterfiend); MIT license

require 'pry'
require 'pry-stack_explorer'
require "pry-exception_explorer/version"
require "pry-exception_explorer/lazy_frame"
require "pry-exception_explorer/commands"
require "pry-exception_explorer/core_ext"
require "pry-exception_explorer/intercept"

if RUBY_VERSION =~ /1.9/
  require 'continuation'
end

module PryExceptionExplorer

  # short-hand for `PryExceptionExplorer`
  ::EE = self

  # special constant
  CONTINUE_INLINE_EXCEPTION = Object.new

  class << self

    # @return [Boolean] Whether exceptions are to be intercepted
    #   inline (at the raise site).
    attr_accessor :inline

    # @return [Boolean] Whether exceptions are to be auto-rescued
    #   if they would terminate the program. 
    attr_accessor :post_mortem

    # @return [Boolean] Holds the previous value of `EE.inline`
    attr_accessor :old_inline_state

    # Ensure exceptions are intercepted at the raise site, and enable EE.
    def inline!
      self.enabled = true 
      self.inline = true
    end

    # Ensure exceptions are intercepted if they would terminate the program, and enable EE.
    def post_mortem!
      self.enabled = true 
      self.post_mortem = true
    end

    alias_method :inline?, :inline
    alias_method :post_mortem?, :post_mortem

    # @return [Hash] A local hash.
    def local_hash
      @hash ||= {}
    end

    # Enable Exception Explorer.
    # @return [Boolean]
    def enable!
      self.enabled = true
    end

    # Disable Exception Explorer.
    # @return [Boolean]
    def disable!
      self.enabled = false
    end

    # @param [Boolean] v Whether Exception Explorer is enabled.
    def enabled=(v)
      local_hash[:enabled] = v
    end

    # @return [Boolean] Whether Exception Explorer is enabled.
    def enabled
      !!local_hash[:enabled]
    end

    alias_method :enabled?, :enabled

    # Wrap the provided block - intercepting all exceptions
    # that bubble out, provided they satisfy the
    # assertion in `PryExceptionExplorer.intercept`.
    # @yield The block to wrap.
    def wrap
      old_enabled, old_inline = enabled, inline
      self.inline      = false
      self.enabled     = true
      yield
    rescue Exception => ex
      if ex.should_intercept?
        enter_exception(ex)
      else
        raise ex
      end
    ensure
      self.enabled = old_enabled
      self.inline  = old_inline
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
      return if exceptions.empty? && block.nil?

      if !exceptions.empty?
        block = proc { |_, ex| exceptions.any? { |v| v === ex } }
      end

      local_hash[:intercept_object] = Intercept.new(block)
    end

    # @return [PryExceptionExplorer::Intercept] The object defined earlier by a call to `PryExceptionExplorer.intercept`.
    def intercept_object=(b)
      local_hash[:intercept_object] = b
    end

    # @return [PryExceptionExplorer::Intercept] The object defined earlier by a call to `PryExceptionExplorer.intercept`.
    def intercept_object
      local_hash[:intercept_object]
    end

    # This method invokes the `PryExceptionExplorer.intercept_object`,
    # passing in the exception's frame and the exception object itself.
    # @param [Binding] frame The stack frame where the exception occurred.
    # @param [Exception] ex The exception that was raised.
    # @return [Boolean] Whether the exception should be intercepted.
    def should_intercept_exception?(frame, ex)
      # special case, or we go into infinite loop. CodeRay uses
      # exceptions for flow control :/
      if defined?(CodeRay::Encoders) && frame.eval('self') == CodeRay::Encoders
        false

        # normal case
      elsif intercept_object
        intercept_object.call(LazyFrame.new(frame), ex)
      else
        false
      end
    end

    # Amends (destructively) an exception call stack according to the info in
    # `PryExceptionExplorer.intercept_object`, specifically
    # `PryExceptionExplorer::Intercept#skip_until_block` and `PryExceptionExplorer::Intercept#skip_while_block`.
    # @param [Exception] ex The exception whose call stack will be amended.
    def amend_exception_call_stack!(ex)
      call_stack = ex.exception_call_stack

      # skip_until
      if intercept_object.skip_until_block
        idx = call_stack.each_with_index.find_index do |frame, idx|
          intercept_object.skip_until_block.call(LazyFrame.new(frame, idx, call_stack))
        end
        call_stack = call_stack.drop(idx) if idx

      # skip_while
      elsif intercept_object.skip_while_block
        idx = call_stack.each_with_index.find_index do |frame, idx|
          intercept_object.skip_while_block.call(LazyFrame.new(frame, idx, call_stack)) == false
        end
        call_stack = call_stack.drop(idx) if idx
      end

      ex.exception_call_stack = call_stack
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
      _pry_.backtrace = (ex.backtrace || [])

      PryStackExplorer.frame_manager(_pry_).user[:exception]        = ex
      PryStackExplorer.frame_manager(_pry_).user[:inline_exception] = !!options[:inline]
    end

    # Enter the exception context.
    # @param [Exception] ex The exception.
    # @param [Hash] options The optional configuration parameters.
    # @option options [Boolean] :inline Whether the exception is being
    #   entered inline (i.e within the `raise` method itself)
    def enter_exception(ex, options={})
      hooks = Pry.config.hooks.dup
      hooks.delete_hook(:before_session, :default)
      hooks.add_hook(:before_session, :set_exception_flag) do |_, _, _pry_|
        setup_exception_context(ex, _pry_, options)
      end.add_hook(:before_session, :manage_intercept_recurse) do
        PryExceptionExplorer.intercept_object.disable! if PryExceptionExplorer.inline? && !PryExceptionExplorer.intercept_object.intercept_recurse?
      end.add_hook(:after_session, :manage_intercept_recurse) do
        PryExceptionExplorer.intercept_object.enable! if !PryExceptionExplorer.intercept_object.active?
      end.add_hook(:before_session, :display_exception) do |_, _, _pry_|
        _pry_.run_command "cat --ex"
      end
      
      Pry.start binding, :call_stack => ex.exception_call_stack, :hooks => hooks
    end

    # Set initial state
    def init
      # disable EE by default
      PryExceptionExplorer.enabled = false

      # auto-start sessions on exceptions that would kill the program
      PryExceptionExplorer.post_mortem = false

      # default is to capture all exceptions
      PryExceptionExplorer.intercept(Exception)

      # disable inline sessions by defulat
      PryExceptionExplorer.inline = false
      at_exit do
        ex = $!
        
        next if !PryExceptionExplorer.post_mortem? || !ex
        
        if ex.should_intercept?
          enter_exception(ex)
        else
          raise ex
        end
      end
    end
  end
end

# Set up enter-exception style exception handling by default for pry sessions
Pry.config.hooks.add_hook(:before_session, :try_enable_exception_explorer) do
  PryExceptionExplorer.enabled          = true
  PryExceptionExplorer.old_inline_state = PryExceptionExplorer.inline
  PryExceptionExplorer.inline           = false
end.add_hook(:after_session, :restore_inline_state) do
  PryExceptionExplorer.inline = PryExceptionExplorer.old_inline_state
end
  
# Bring in commands
Pry.config.commands.import PryExceptionExplorer::Commands

# Set initial state
PryExceptionExplorer.init


