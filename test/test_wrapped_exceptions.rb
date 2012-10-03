require 'helper'

CaughtException   = Class.new(StandardError)
UncaughtException = Class.new(StandardError)

describe PryExceptionExplorer do

  before do
    PryExceptionExplorer.enabled = true
    Pry.config.input = StringIO.new("exit :caught\n")
    Pry.config.output = StringIO.new
    Pry.config.hooks.add_hook(:when_started, :save_caller_bindings, WhenStartedHook)
    Pry.config.hooks.add_hook(:after_session, :delete_frame_manager, AfterSessionHook)
  end

  after do
    Pad.clear
    Pry.config.hooks.delete_hook(:when_started, :save_caller_bindings)
    Pry.config.hooks.delete_hook(:after_session, :delete_frame_manager)
  end

  describe "PryExceptionExplorer.wrap" do

    describe "_ex_" do
      it 'should correctly set _ex_ inside session (set to raised exception)' do
        ex = Class.new(StandardError)
        o = Object.new
        class << o; attr_accessor :ex; self; end.class_eval { define_method(:raze) { raise ex } }

        PryExceptionExplorer.intercept { true }

        redirect_pry_io(InputTester.new("@ex = _ex_", "exit-all")) do
          PryExceptionExplorer.wrap do
            o.raze
          end
        end

        o.ex.is_a?(ex).should == true
      end
    end

    describe "_pry_.backtrace" do
      it 'should correctly set _pry_ inside session to backtrace of raised exception' do
        ex = Class.new(StandardError)
        o = Object.new
        class << o; attr_accessor :ex, :pry_bt; self; end.class_eval { define_method(:raze) { raise ex } }

        PryExceptionExplorer.intercept { true }

        redirect_pry_io(InputTester.new("@ex = _ex_", "@pry_bt = _pry_.backtrace", "exit-all")) do
          PryExceptionExplorer.wrap do
            o.raze
          end
        end

        o.pry_bt.should == o.ex.backtrace
      end
    end

    describe "internal exceptions" do
      it 'should be able to intercept internal exceptions' do
        redirect_pry_io(InputTester.new("Pad.ex = _ex_", "exit-all")) do
          PryExceptionExplorer.wrap do
            (1 / 0)
          end rescue nil
        end

        Pad.ex.is_a?(ZeroDivisionError).should == true
      end

      it 'should not intercept rescued exceptions' do
        redirect_pry_io(InputTester.new("Pad.ex = _ex_", "exit-all")) do
          PryExceptionExplorer.wrap do
            (1 / 0) rescue nil
          end 
        end

        Pad.ex.should == nil
      end

      it 'should not be able to continue exceptions' do
        redirect_pry_io(InputTester.new("continue-exception"), out=StringIO.new) do
          PryExceptionExplorer.wrap do
            (1 / 0) 
          end 
        end

        out.string.should =~ /cannot be continued/
      end
    end

    describe "enabled = false" do
      it 'should have no effect for wrap block (which sets enabled=true internally)' do
        old_e = PryExceptionExplorer.enabled
        PryExceptionExplorer.enabled = false
        PryExceptionExplorer.wrap do
          raise CaughtException, "catch me if u can"
        end.should == :caught

        PryExceptionExplorer.enabled.should == false
        PryExceptionExplorer.enabled = old_e
      end
    end

    # use of exit-exception inside a wrapped exception is weird
    # (because exit-exception is really designed for pry exceptions)
    # but when we do receive one, we should exit out of pry
    # altogether.
    # This test is weird as we can't use lambda { }.should.not.raise, as we override
    # 'raise' method ourself, which kills bacon's functionality here.
    it 'should exit out of Pry session when using exit-exception' do
      PryExceptionExplorer.intercept { true }

      x = :no_exception_raised
      redirect_pry_io(InputTester.new("exit-exception"), StringIO.new) do
        PryExceptionExplorer.wrap do
          Ratty.new.ratty
        end
      end
      x.should == :no_exception_raised
    end

    it 'should default to capturing ALL exceptions' do
      PryExceptionExplorer.wrap do
        raise CaughtException, "catch me if u can"
      end.should == :caught
    end

    it 'should NOT capture rescued exceptions' do
      o = Object.new
      def o.evil_fish
        Ratty.new.ratty
      rescue Exception
      end

      PryExceptionExplorer.intercept { true }

      PryExceptionExplorer.wrap do
        o.evil_fish
      end.should.not == :caught
    end

    it 'should have the full callstack attached to exception' do
      PryExceptionExplorer.intercept { |frame, ex| frame.method_name == :toad }

      PryExceptionExplorer.wrap do
        begin
          Ratty.new.ratty
        rescue Exception => ex
          ex.exception_call_stack[0..2].map { |b| b.eval("__method__") }.should == [:toad, :weasel, :ratty]
        end
      end
    end

    it 'should NOT have callstack attached if exception not matched' do
      PryExceptionExplorer.intercept { |frame, ex| false }

      begin
        PryExceptionExplorer.wrap do
          raise UncaughtException, "Catch me if you can't.."
        end
      rescue UncaughtException => ex
        ex.exception_call_stack.should == nil
      end
    end

    describe "PryExceptionExplorer.intercept with wrapped exceptions" do
      describe "klass" do
        describe "first frame" do
          it 'should catch a matched exception based on klass' do
            PryExceptionExplorer.intercept { |frame, ex| frame.klass == Toad }

            PryExceptionExplorer.wrap do
              Ratty.new.ratty
            end.should == :caught
          end

          it 'should NOT catch an unmatched exception' do
            PryExceptionExplorer.intercept { |frame, ex| frame.klass == Weasel }

            begin
              PryExceptionExplorer.wrap do
                raise UncaughtException, "Catch me if you can't.."
              end
            rescue Exception => ex
              ex.is_a?(UncaughtException).should == true
            end
          end
        end

        describe "third frame" do
          it 'should catch a matched exception' do
            PryExceptionExplorer.intercept { |frame, ex| frame.prev.prev.klass == Ratty }

            PryExceptionExplorer.wrap do
              Ratty.new.ratty
            end.should == :caught
          end

          it 'should NOT catch an unmatched exception' do
            PryExceptionExplorer.intercept { |frame, ex| frame.prev.prev.klass == Weasel }

            begin
              PryExceptionExplorer.wrap do
                raise UncaughtException, "Catch me if you can't.."
              end
            rescue Exception => ex
              ex.is_a?(UncaughtException).should == true
            end
          end
        end
      end

      describe "method_name" do
        describe "first frame" do
          it 'should catch a matched exception' do
            PryExceptionExplorer.intercept { |frame, ex| frame.method_name == :toad }

            PryExceptionExplorer.wrap do
              Ratty.new.ratty
            end.should == :caught
          end

          it 'should NOT catch an unmatched exception' do
            PryExceptionExplorer.intercept { |frame, ex| frame.method_name == :weasel }

            begin
              PryExceptionExplorer.wrap do
                raise UncaughtException, "Catch me if you can't.."
              end
            rescue Exception => ex
              ex.is_a?(UncaughtException).should == true
            end
          end
        end

        describe "third frame" do
          it 'should catch a matched exception' do
            PryExceptionExplorer.intercept { |frame, ex| frame.prev.prev.method_name == :ratty }

            PryExceptionExplorer.wrap do
              Ratty.new.ratty
            end.should == :caught
          end

          it 'should NOT catch an unmatched exception' do
            PryExceptionExplorer.intercept { |frame, ex| frame.prev.prev.method_name == :weasel }

            begin
              PryExceptionExplorer.wrap do
                raise UncaughtException, "Catch me if you can't.."
              end
            rescue Exception => ex
              ex.is_a?(UncaughtException).should == true
            end
          end
        end

      end
    end
  end
end
