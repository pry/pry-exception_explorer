require 'pry_stack_explorer'

Pry.config.hooks.delete_hook(:when_started, :save_caller_bindings)

module PryExceptionExplorer
  def self.wrap
    yield
  rescue Exception => ex
    Pry.config.hooks.add_hook(:when_started, :setup_exception_context) do |binding_stack, _pry_|
      binding_stack.replace([ex.exception_call_stack.first])
      PryStackExplorer.create_and_push_frame_manager(ex.exception_call_stack, _pry_)
      PryStackExplorer.frame_manager(_pry_).user[:exception] = ex
    end

    pry
  end
end
