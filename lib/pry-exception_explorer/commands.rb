require 'pry-stack_explorer'

PryExceptionExplorer::Commands = Pry::CommandSet.new do

  command "enter-exception", "Enter the context of the last exception" do
    ex = _pry_.last_exception
    if ex && ex.exception_call_stack
      PryStackExplorer.create_and_push_frame_manager(ex.exception_call_stack, _pry_)
      PryExceptionExplorer.setup_exception_context(ex, _pry_)
      PryStackExplorer.frame_manager(_pry_).refresh_frame
    elsif ex
      output.puts "Current exception can't be entered! (perhaps a C exception)"
    else
      output.puts "No exception to enter!"
    end
  end

  command_class "exit-exception", "Leave the context of the current exception." do
    banner <<-BANNER
      Usage: exit-exception
      Exit active exception and return to containing context.
    BANNER

    def process
      if !in_exception?
        raise Pry::CommandError, "You are not in an exception!"
      elsif !prior_context_exists?
        run "exit-all"
      else
        popped_fm = PryStackExplorer.pop_frame_manager(_pry_)
        if frame_manager
          frame_manager.refresh_frame
        else
          _pry_.binding_stack[-1] = popped_fm.prior_binding
        end
        _pry_.last_exception = popped_fm.user[:exception]
      end
    end

    private
    def frame_manager
      PryStackExplorer.frame_manager(_pry_)
    end

    def frame_managers
      PryStackExplorer.frame_managers(_pry_)
    end

    def prior_context_exists?
      frame_managers.count > 1 || frame_manager.prior_binding
    end

    def in_exception?
      frame_manager && frame_manager.user[:exception]
    end
  end

  command "continue-exception", "Attempt to continue the current exception." do
    fm = PryStackExplorer.frame_manager(_pry_)

    if fm && fm.user[:exception] && fm.user[:inline_exception]
      PryStackExplorer.pop_frame_manager(_pry_)
      _pry_.run_command "exit-all PryExceptionExplorer::CONTINUE_INLINE_EXCEPTION"
    elsif fm && fm.user[:exception] && fm.user[:exception].continuation
      PryStackExplorer.pop_frame_manager(_pry_)
      fm.user[:exception].continue
    else
      output.puts "No exception to continue!"
    end
  end

end
