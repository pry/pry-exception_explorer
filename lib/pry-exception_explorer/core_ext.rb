# `PryExceptionExplorer` monkey-patches to `Exception`
class Exception
  NoContinuation = Class.new(StandardError)

  # @return [Continuation] The continuation object for the exception.
  #   Invoking this continuation will allow the program to continue
  #   from the point the exception was raised.
  attr_accessor :continuation

  # @return [Array<Binding>] The array of bindings that represent the
  #   call stack for the exception. This is navigable inside the Pry
  #   session with the `up` and `down` and `frame` commands.
  attr_accessor :exception_call_stack

  # @return [Boolean] Whether this exception should be intercepted.
  #   (Only relevant for wrapped exceptions).
  attr_accessor :should_intercept

  # This method enables us to continue an exception (using
  # `callcc` internally)
  def continue
    raise NoContinuation unless continuation.respond_to?(:call)
    continuation.call
  end

  alias_method :should_intercept?, :should_intercept
end

# `PryExceptionExplorer` monkey-patches to `Object`
module PryExceptionExplorer
  module CoreExtensions

    #  We monkey-patch the `raise` method so we can intercept exceptions
    def raise(*args)
      exception, string, array = args

      if exception.is_a?(String)
        string = exception
        exception = RuntimeError
      end

      if exception.is_a?(Exception) || (exception.is_a?(Class) && exception < Exception)
        if PryExceptionExplorer.enabled?
          ex = string ? exception.exception(string) : exception.exception
        else
          return super(*args)
        end
      elsif exception.nil?
        if $!
          if PryExceptionExplorer.enabled?
            ex = $!.exception
          else
            return super($!)
          end
        else
          if PryExceptionExplorer.enabled?
            ex = RuntimeError.exception
          else
            return super(RuntimeError)
          end
        end
      else
        if PryExceptionExplorer.enabled?
          ex = RuntimeError.exception
        else
          return super(*args)
        end
      end

      ex.set_backtrace(array ? array : caller)

      intercept_object = PryExceptionExplorer.intercept_object

      # FIXME: CodeRay stuff is a hack because CodeRay generates a bunch of
      # exceptions that would cause EE to infiniloop on
      # intercept(Exception), find a better solution.
      if PryExceptionExplorer.should_intercept_exception?(binding.of_caller(1), ex) &&
          binding.of_caller(1).eval('[__method__, self.to_s]') != [:make_plugin_hash, "CodeRay::Encoders"]

        ex.exception_call_stack = binding.callers.tap { |v| v.shift(1 + intercept_object.skip_num) }
        PryExceptionExplorer.amend_exception_call_stack!(ex)

        ex.should_intercept  = true

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
end


class Object
  include PryExceptionExplorer::CoreExtensions
end
