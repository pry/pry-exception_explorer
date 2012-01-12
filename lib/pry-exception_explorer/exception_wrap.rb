require 'pry-exception_explorer'

#Pry.config.hooks.delete_hook(:when_started, :save_caller_bindings)

# default is to capture all exceptions that bubble to the top
PryExceptionExplorer.intercept { true }

module PryExceptionExplorer

  def self.wrap
    old_enabled, old_wrap_active = enabled, wrap_active
    self.enabled     = true
    self.wrap_active = true
    yield
  rescue Exception => ex
    if ex.should_capture?
      hooks = Pry.config.hooks.dup.add_hook(:before_session, :set_exception_flag) do |_, _, _pry_|
        PryStackExplorer.frame_manager(_pry_).user[:exception] = ex

        _pry_.last_exception = ex
        _pry_.backtrace = ex.backtrace
      end

      Pry.start self, :call_stack => ex.exception_call_stack, :hooks => hooks
    else
      raise ex
    end
  ensure
    self.enabled     = old_enabled
    self.wrap_active = old_wrap_active
  end
end

