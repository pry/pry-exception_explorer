require 'pry-stack_explorer'

PryExceptionExplorer::Commands = Pry::CommandSet.new do

  command "enter-exception", "Enter the context of the last exception" do
    ex = _pry_.last_exception
    if ex && ex.exception_call_stack
      PryStackExplorer.create_and_push_frame_manager(ex.exception_call_stack, _pry_)
      PryStackExplorer.frame_manager(_pry_).user[:exception] = ex
      PryStackExplorer.frame_manager(_pry_).refresh_frame
    elsif ex
      output.puts "Current exception can't be entered! (perhaps a C exception)"
    else
      output.puts "No exception to enter!"
    end
  end

  command "exit-exception", "Leave the context of the current exception." do
    fm = PryStackExplorer.frame_manager(_pry_)
    if fm && fm.user[:exception]
      PryStackExplorer.pop_frame_manager(_pry_)
      PryStackExplorer.frame_manager(_pry_).refresh_frame
    else
      output.puts "You are not in an exception!"
    end
  end

  command "continue-exception", "Attempt to continue the current exception." do
    fm = PryStackExplorer.frame_manager(_pry_)

    if fm && fm.user[:exception] && fm.user[:inline_exception]
       _pry_.run_command "exit-all PryExceptionExplorer::CONTINUE_INLINE_EXCEPTION"
      PryStackExplorer.pop_frame_manager(_pry_)
    elsif fm && fm.user[:exception] && fm.user[:exception].continuation
      PryStackExplorer.pop_frame_manager(_pry_)
      fm.user[:exception].continue
    else
      output.puts "No exception to continue!"
    end
  end

end
