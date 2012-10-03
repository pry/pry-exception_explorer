require 'helper'
require 'ostruct'

# globally accessible state
O = OpenStruct.new



prev_intercept_state = PryExceptionExplorer.intercept_object

PryExceptionExplorer.inline!
PryExceptionExplorer.enabled = true

describe PryExceptionExplorer do

  before do
    O.exception_intercepted = false

    # Ensure that when an exception is intercepted (a pry session
    # started) that this is registered by setting state on `O`
    Pry.config.input = StringIO.new("O.exception_intercepted = true\ncontinue-exception")
    Pry.config.output = StringIO.new
    Pry.config.hooks.add_hook(:when_started, :save_caller_bindings, WhenStartedHook)
    Pry.config.hooks.add_hook(:after_session, :delete_frame_manager, AfterSessionHook)
  end

  after do
    Pry.config.input.rewind
    Pry.config.hooks.delete_hook(:when_started, :save_caller_bindings)
    Pry.config.hooks.delete_hook(:after_session, :delete_frame_manager)
    O.clear
  end

  describe "internal exceptions" do
    it 'should intercept internal exceptions inline' do
      redirect_pry_io(StringIO.new("O.exception_intercepted = true\nexit-all\n"), out=StringIO.new) do
        (1 / 0) rescue nil
      end
      
      O.exception_intercepted.should == true
    end

    it 'should be un-continuable' do
      redirect_pry_io(StringIO.new("O.exception_intercepted = true\ncontinue-exception\n"), out=StringIO.new) do
        (1 / 0) rescue nil
      end
      out.string.should =~ /cannot be continued/
    end
  end

  describe "enabled = false" do
    it 'should prevent interception of an exception' do
      old_e = PryExceptionExplorer.enabled
      PryExceptionExplorer.enabled = false

      my_error = Class.new(StandardError)
      EE.intercept(my_error)

      begin
        raise my_error
      rescue => ex
        exception = ex
      end

      exception.is_a?(my_error).should == true

      PryExceptionExplorer.enabled = old_e
    end
  end

  describe "PryExceptionExplorer.intercept" do
    it 'should be a no-op when intercept called with no parameters' do
      b = proc {}
      old = EE.intercept_object
      EE.intercept &b
      EE.intercept
      EE.intercept_object.block.should == b
      EE.intercept_object = old
    end

    # * DEPRECATED * this test is no longer relevant as in-session exception handling is now restricted to enter-exception style
    # 
    # describe "intercept_recurse" do
    #   it 'should NOT allow recursive (in-session) interceptions by default' do
    #     EE.intercept { |frame, ex| frame.klass == Toad }

    #     redirect_pry_io(InputTester.new("O.before_self = self",
    #                                     "Ratty.new.ratty",
    #                                     "O.after_self = self",
    #                                     "continue-exception",
    #                                     "continue-exception")) do
    #       Ratty.new.ratty
    #     end

    #     O.before_self.should == O.after_self
    #   end

    #   it 'should allow recursive (in-session) interceptions when :intercept_recurse => true' do
    #     EE.intercept { |frame, ex| frame.klass == Toad }.intercept_recurse(true)

    #     redirect_pry_io(InputTester.new("O.before_self = self",
    #                                     "Ratty.new.ratty",
    #                                     "O.after_self = self",
    #                                     "continue-exception",
    #                                     "continue-exception")) do
    #       Ratty.new.ratty
    #     end

    #     O.before_self.should.not == O.after_self
    #   end
    # end

    describe "skip" do
      it 'should skip first frame with :skip => 1' do
        EE.intercept { |frame, ex| frame.klass == Toad }.skip(1)

        redirect_pry_io(InputTester.new("O.method_name = __method__",
                                        "continue-exception")) do
          Ratty.new.ratty
        end

        O.method_name.should == :weasel
      end

      it 'should skip first two framed with :skip => 2' do
        EE.intercept { |frame, ex| frame.klass == Toad }.skip(2)

        redirect_pry_io(InputTester.new("O.method_name = __method__",
                                        "continue-exception")) do
          Ratty.new.ratty
        end

        O.method_name.should == :ratty
      end
    end

    describe "skip_until" do
      it 'should skip frames until it finds a frame that meets the predicate' do
        EE.intercept { |frame, ex| frame.klass == Toad }.skip_until { |frame| frame.prev.method_name == :ratty }

        redirect_pry_io(InputTester.new("O.method_name = __method__",
                                        "continue-exception")) do
          Ratty.new.ratty
        end

        O.method_name.should == :weasel
      end

      it 'should not skip any frames if predicate not met' do
        EE.intercept { |frame, ex| frame.klass == Toad }.skip_until { |frame| frame.prev.method_name == :will_not_be_matched }

        redirect_pry_io(InputTester.new("O.method_name = __method__",
                                        "continue-exception")) do
          Ratty.new.ratty
        end

        O.method_name.should == :toad
      end
    end

    describe "skip_while" do
      it 'should skip frames while no frames meets the predicate' do
        EE.intercept { |frame, ex| frame.klass == Toad }.skip_while { |frame| frame.prev.method_name != :ratty }

        redirect_pry_io(InputTester.new("O.method_name = __method__",
                                        "continue-exception")) do
          Ratty.new.ratty
        end

        O.method_name.should == :weasel
      end

      it 'should not skip any frames if predicate not met' do
        EE.intercept { |frame, ex| frame.klass == Toad }.skip_while { |frame| frame.prev.method_name != :will_not_be_matched }

        redirect_pry_io(InputTester.new("O.method_name = __method__",
                                        "continue-exception")) do
          Ratty.new.ratty
        end

        O.method_name.should == :toad
      end
    end
   
    describe "resetting inline EE state when leaving session" do

      before do
        Pry.config.hooks.add_hook(:before_session, :try_enable_exception_explorer) do
          PryExceptionExplorer.enabled          = true
          PryExceptionExplorer.old_inline_state = PryExceptionExplorer.inline
          PryExceptionExplorer.inline           = false
        end.add_hook(:after_session, :restore_inline_state) do
          PryExceptionExplorer.inline = PryExceptionExplorer.old_inline_state
        end
      end

      after do
        Pry.config.hooks.delete_hook(:before_session, :try_enable_exception_explorer)
        Pry.config.hooks.delete_hook(:after_session, :restore_inline_state)
      end

      it 'should have EE.inline set to false inside a session, and true outside the session' do
        EE.intercept(Exception)
        EE.inline!
        redirect_pry_io(InputTester.new("O.in_session_inline_state = EE.inline",
                                        "continue-exception")) do
          raise "The children were crying, dreaming of the open beaks of dying birds."
        end

        O.in_session_inline_state.should == false
        EE.inline.should == true
      end
    end

    describe "special case exception-only syntax" do
      describe "single exception" do
        it 'should intercept provided exceptions when given parameters (and no block)' do
          my_error = Class.new(StandardError)
          EE.intercept(my_error)
          raise my_error
          O.exception_intercepted.should == true
        end

        it 'should NOT intercept provided exceptions when not matched' do
          my_error = Class.new(StandardError)
          EE.intercept(my_error)

          begin
            raise RuntimeError
          rescue => ex
            ex.is_a?(RuntimeError).should == true
          end
        end
      end

      describe "multiple exceptions" do
        it 'should intercept provided exceptions when given parameters (and no block)' do
          errors = Array.new(3) { Class.new(StandardError) }
          EE.intercept(*errors)

          errors.each do |my_error|
            raise my_error
            O.exception_intercepted.should == true
            O.exception_intercepted  = false
            Pry.config.input.rewind
          end
        end

        it 'should NOT intercept provided exceptions when not matched' do
          errors = Array.new(3) { Class.new(StandardError) }

          EE.intercept(*errors)

          errors.each do |my_error|
            begin
              raise RuntimeError
            rescue => ex
              ex.is_a?(RuntimeError).should == true
            end
          end
        end
      end

    end

    describe "class" do
      describe "first frame" do
        it  "should intercept exception based on first frame's class" do
          EE.intercept { |frame, ex| frame.klass == Toad }
          Ratty.new.ratty
          O.exception_intercepted.should == true
        end

        it  "should NOT intercept exception if class doesn't match" do
          EE.intercept { |frame, ex| frame.klass == Ratty }
          begin
            Ratty.new.ratty
          rescue Exception => ex
            ex.is_a?(RuntimeError).should == true
          end
          O.exception_intercepted.should == false
        end
      end

      describe "second frame" do
        it  "should intercept exception based on second frame's method name" do
          EE.intercept { |frame, ex| frame.prev.klass == Weasel }
          begin
            Ratty.new.ratty
          rescue => ex
            Pry.new(:input => Readline, :output =>
                    $stdout).repl(binding)
          end
          O.exception_intercepted.should == true
        end

        it  "should NOT intercept exception if method name doesn't match" do
          EE.intercept { |frame, ex| frame.prev.klass == Toad }
          begin
            Ratty.new.ratty
          rescue Exception => ex
            ex.is_a?(RuntimeError).should == true
          end
          O.exception_intercepted.should == false
        end
      end

      describe "third frame" do
        it  "should intercept exception based on third frame's method name" do
          EE.intercept { |frame, ex| frame.prev.prev.klass == Ratty }
          Ratty.new.ratty
          O.exception_intercepted.should == true
        end

        it  "should NOT intercept exception if method name doesn't match" do
          EE.intercept { |frame, ex| frame.prev.prev.klass == Toad }
          begin
            Ratty.new.ratty
          rescue Exception => ex
            ex.is_a?(RuntimeError).should == true
          end
          O.exception_intercepted.should == false
        end
      end

    end

    describe "method_name" do
      describe "first frame" do
        it  "should intercept exception based on first frame's method name" do
          EE.intercept { |frame, ex| frame.method_name == :toad }
          Ratty.new.ratty
          O.exception_intercepted.should == true
        end

        it  "should NOT intercept exception if method name doesn't match" do
          EE.intercept { |frame, ex| frame.method_name == :ratty }
          begin
            Ratty.new.ratty
          rescue Exception => ex
            ex.is_a?(RuntimeError).should == true
          end
          O.exception_intercepted.should == false
        end
      end

      describe "second frame" do
        it  "should intercept exception based on second frame's method name" do
          EE.intercept { |frame, ex| frame.prev.method_name == :weasel }
          Ratty.new.ratty
          O.exception_intercepted.should == true
        end

        it  "should NOT intercept exception if method name doesn't match" do
          EE.intercept { |frame, ex| frame.prev.method_name == :toad }
          begin
            Ratty.new.ratty
          rescue Exception => ex
            ex.is_a?(RuntimeError).should == true
          end
          O.exception_intercepted.should == false
        end
      end

      describe "third frame" do
        it  "should intercept exception based on third frame's method name" do
          EE.intercept { |frame, ex| frame.prev.prev.method_name == :ratty }
          Ratty.new.ratty
          O.exception_intercepted.should == true
        end

        it  "should NOT intercept exception if method name doesn't match" do
          EE.intercept { |frame, ex| frame.prev.prev.method_name == :toad }
          begin
            Ratty.new.ratty
          rescue Exception => ex
            ex.is_a?(RuntimeError).should == true
          end
          O.exception_intercepted.should == false
        end
      end

    end


  end

  describe "call-stack management" do
    it 'should pop the call-stack after session ends (continue)' do
      EE.intercept { |frame, ex| frame.prev.prev.method_name == :ratty }

      redirect_pry_io(InputTester.new(
                                      "O.stack_count = PryStackExplorer.frame_managers(_pry_).count",
                                      "O._pry_ = _pry_",
                                      "continue-exception"), StringIO.new) do
        Ratty.new.ratty
      end
      O.stack_count.should == 1
      PryStackExplorer.frame_managers(O._pry_).count.should == 0
    end

    it 'should pop the call-stack after session ends (exit)' do
      EE.intercept { |frame, ex| frame.prev.prev.method_name == :ratty }

      redirect_pry_io(InputTester.new(
                                      "O.stack_count = PryStackExplorer.frame_managers(_pry_).count",
                                      "O._pry_ = _pry_",
                                      "exit"), StringIO.new) do
        begin
          Ratty.new.ratty
        rescue
        end
      end
      O.stack_count.should == 1
      PryStackExplorer.frame_managers(O._pry_).count.should == 0
    end

    # * DEPRECATED * this test is no longer relevant as in-session exception handling is now restricted to enter-exception style
    # 
    # describe "nested exceptions" do
    #   it 'Each successive exception interception should be managed by its own pry instance and have its own call-stack' do
    #     EE.intercept { |frame, ex| frame.prev.prev.method_name == :ratty }

    #     redirect_pry_io(InputTester.new(
    #                                     "O.first_stack_count = PryStackExplorer.frame_managers(_pry_).count",
    #                                     "O._pry_ = _pry_",
    #                                     "EE.intercept(ArgumentError)",
    #                                     "raise ArgumentError",
    #                                     "O._pry_2 = _pry_",
    #                                     "O.second_stack_count = PryStackExplorer.frame_managers(_pry_).count",
    #                                     "continue-exception",
    #                                     "continue-exception"), StringIO.new) do
    #       Ratty.new.ratty
    #     end

    #     O._pry_.should.not == O._pry_2
    #     O.first_stack_count.should == 1
    #     O.second_stack_count.should == 1
    #     PryStackExplorer.frame_managers(O._pry_).count.should == 0
    #     PryStackExplorer.frame_managers(O._pry_2).count.should == 0
    #   end

    # end

    describe "exit-exception" do
      it 'should exit session and raise exception' do
        my_error = Class.new(StandardError)
        EE.intercept(my_error)

        begin
          redirect_pry_io(InputTester.new("exit-exception")) do
            raise my_error
          end
        rescue => ex
          exception = ex
        end

        exception.is_a?(my_error).should == true
      end
    end

  end

end

# restore to default
PryExceptionExplorer.intercept_object = prev_intercept_state

Object.send(:remove_const, :O)
