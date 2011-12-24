require 'helper'

require 'pry-exception_explorer/exception_wrap'

CaughtException   = Class.new(StandardError)
UncaughtException = Class.new(StandardError)

describe PryExceptionExplorer do

  before do
    Pry.config.input = StringIO.new("exit :caught\n")
    Pry.config.output = StringIO.new
  end

  after do
    Pry.config.hooks.clear(:when_started)
  end

  describe "PryExceptionExplorer.wrap" do

    it 'should not capture rescued exceptions' do
      o = Object.new
      def o.evil_fish
        Ratty.new.ratty
      rescue Exception
      end

      PryExceptionExplorer.intercept { |frame, ex| frame.method_name == :toad }

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
