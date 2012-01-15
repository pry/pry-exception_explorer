# `PryExceptionExplorer` monkey-patches to `Exception`
class Exception
  NoContinuation = Class.new(StandardError)

  attr_accessor :continuation
  attr_accessor :exception_call_stack
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
class Object

  # We monkey-patch the `raise` method so we can intercept exceptions
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

    if PryExceptionExplorer.should_intercept_exception?(binding.of_caller(1), ex)
      ex.exception_call_stack = binding.callers.tap(&:shift)
      ex.should_intercept       = true

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
