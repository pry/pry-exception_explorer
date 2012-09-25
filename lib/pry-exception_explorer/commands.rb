require 'pry-stack_explorer'

module PryExceptionExplorer
  module ExceptionHelpers
    include PryStackExplorer::FrameHelpers

    private
    def in_exception?
      frame_manager && frame_manager.user[:exception]
    end

    def last_exception
      _pry_.last_exception
    end

    def enterable_exception?
      PryExceptionExplorer.enabled && last_exception && last_exception.exception_call_stack
    end

    def inline_exception?
      frame_manager && frame_manager.user[:exception] &&
        frame_manager.user[:inline_exception]
    end

    def normal_exception?
      frame_manager && frame_manager.user[:exception] &&
        frame_manager.user[:exception].continuation
    end
  end

  Commands = Pry::CommandSet.new do
    create_command "enter-exception", "Enter the context of the last exception" do
      include PryExceptionExplorer::ExceptionHelpers

      banner <<-BANNER
        Usage: enter-exception
        Enter the context of the last exception
      BANNER

      def process
        if enterable_exception?
          PryStackExplorer.create_and_push_frame_manager(last_exception.exception_call_stack, _pry_)
          PryExceptionExplorer.setup_exception_context(last_exception, _pry_)

          # have to use _pry_.run_command instead of 'run' here as
          # 'run' works on the current target which hasnt been updated
          # yet, whereas _pry_.run_command operates on the newly
          # updated target (the context of the exception)
          _pry_.run_command "whereami"
        elsif last_exception
          raise Pry::CommandError, "Current exception can't be entered! (perhaps a C exception)"
        else
          raise Pry::CommandError,  "No exception to enter!"
        end
      end
    end

    create_command "exit-exception", "Leave the context of the current exception." do
      include ExceptionHelpers

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
          _pry_.last_exception = popped_fm.user[:exception]
        end
      end
    end

    create_command "continue-exception", "Attempt to continue the current exception." do
      include ExceptionHelpers

      banner <<-BANNER
        Usage: continue-exception
        Attempt to continue the current exception.
      BANNER

      def process
        if inline_exception?
          PryStackExplorer.pop_frame_manager(_pry_)
          run "exit-all PryExceptionExplorer::CONTINUE_INLINE_EXCEPTION"
        elsif normal_exception?
          popped_fm = PryStackExplorer.pop_frame_manager(_pry_)
          popped_fm.user[:exception].continue
        else
          raise Pry::CommandError, "No exception to continue!"
        end
      end
    end

  end
end
