require 'pry_stack_explorer'

Pry.config.hooks.delete_hook(:when_started, :save_caller_bindings)

module PryExceptionExplorer
  def self.wrap_active?
    !!Thread.current[:__pry_exception_explorer_wrap__]
  end
  
  def self.wrap
    Thread.current[:__pry_exception_explorer_wrap__] = true
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
    Thread.current[:__pry_exception_explorer_wrap__] = false
  end
end
