require 'pry-stack_explorer'

module PryExceptionExplorer
  module ExceptionHelpers
    include PryStackExplorer::FrameHelpers

    private

    def exception
      frame_manager.user[:exception]
    end

    def in_exception?
      frame_manager && exception
    end

    def last_exception
      _pry_.last_exception
    end

    def enterable_exception?(ex=last_exception)      
      PryExceptionExplorer.enabled && ex && ex.exception_call_stack
    end

    def inline_exception?
      in_exception? &&
        frame_manager.user[:inline_exception]
    end

    def internal_exception?
      in_exception? && exception.internal_exception?
    end

    def normal_exception?
      in_exception? && frame_manager.user[:exception].continuation
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
        ex = extract_exception
        if enterable_exception?(ex)
          PryStackExplorer.create_and_push_frame_manager(ex.exception_call_stack, _pry_)
          PryExceptionExplorer.setup_exception_context(ex, _pry_)

          # have to use _pry_.run_command instead of 'run' here as
          # 'run' works on the current target which hasnt been updated
          # yet, whereas _pry_.run_command operates on the newly
          # updated target (the context of the exception)
          _pry_.run_command "cat --ex 0"
        elsif ex
          raise Pry::CommandError, "Exception can't be entered! (perhaps an internal exception)"
        else
          raise Pry::CommandError,  "No exception to enter!"
        end
      end

      def extract_exception
        if !arg_string.empty?
          ex = target.eval(arg_string)
          raise if !ex.is_a?(Exception)
          ex
        else
          last_exception
        end
      rescue
        raise Pry::CommandError, "Parameter must be a valid exception object."
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
        if internal_exception?
          raise Pry::CommandError, "Internal exceptions (C-level exceptions) cannot be continued!"
        elsif inline_exception?
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
