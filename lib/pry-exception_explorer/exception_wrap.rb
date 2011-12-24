require 'pry-exception_explorer'

Pry.config.hooks.delete_hook(:when_started, :save_caller_bindings)

# default is to capture all exceptions that bubble to the top
PryExceptionExplorer.intercept { true }

module PryExceptionExplorer

  def self.wrap
    self.wrap_active = true
    yield
  rescue Exception => ex
    Pry.config.hooks.add_hook(:when_started, :setup_exception_context) do |binding_stack, _pry_|
      binding_stack.replace([ex.exception_call_stack.first])
      PryStackExplorer.create_and_push_frame_manager(ex.exception_call_stack, _pry_)
      PryStackExplorer.frame_manager(_pry_).user[:exception] = ex
    end

    if ex.should_capture?
      pry
    else
      raise ex
    end
  ensure
    self.wrap_active = false
  end
end

