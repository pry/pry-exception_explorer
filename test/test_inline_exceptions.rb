require 'helper'
require 'ostruct'

# globally accessible state
O = OpenStruct.new

prev_wrap_state = PryExceptionExplorer.wrap_active
PryExceptionExplorer.wrap_active = false

prev_intercept_state = PryExceptionExplorer.intercept_block

describe PryExceptionExplorer do

  before do
    PryExceptionExplorer.wrap_active = false
    O.exception_intercepted = false

    # Ensure that when an exception is intercepted (a pry session
    # started) that this is registered by setting state on `O`
    Pry.config.input = StringIO.new("O.exception_intercepted = true\ncontinue-exception")
    Pry.config.output = StringIO.new
    Pry.config.hooks.add_hook(:when_started, :save_caller_bindings, &WhenStartedHook)
    Pry.config.hooks.add_hook(:after_session, :delete_frame_manager, &AfterSessionHook)
  end

  after do
    Pry.config.input.rewind
    Pry.config.hooks.delete_hook(:when_started, :save_caller_bindings)
    Pry.config.hooks.delete_hook(:after_session, :delete_frame_manager)
    O.clear
  end

  describe "PryExceptionExplorer.intercept" do
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
          Ratty.new.ratty
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

    describe "nested exceptions" do
      it 'Each successive exception interception should be managed by its own pry instance and have its own call-stack' do
        EE.intercept { |frame, ex| frame.prev.prev.method_name == :ratty }

        redirect_pry_io(InputTester.new(
                                        "O.first_stack_count = PryStackExplorer.frame_managers(_pry_).count",
                                        "O._pry_ = _pry_",
                                        "EE.intercept(ArgumentError)",
                                        "raise ArgumentError",
                                        "O._pry_2 = _pry_",
                                        "O.second_stack_count = PryStackExplorer.frame_managers(_pry_).count",
                                        "continue-exception",
                                        "continue-exception"), StringIO.new) do
          Ratty.new.ratty
        end

        O._pry_.should.not == O._pry_2
        O.first_stack_count.should == 1
        O.second_stack_count.should == 1
        PryStackExplorer.frame_managers(O._pry_).count.should == 0
        PryStackExplorer.frame_managers(O._pry_2).count.should == 0
      end

    end

  end

end

# restore to default
PryExceptionExplorer.wrap_active = prev_wrap_state
PryExceptionExplorer.intercept &prev_intercept_state

Object.send(:remove_const, :O)
