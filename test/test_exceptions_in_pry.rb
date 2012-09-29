require 'helper'

O = OpenStruct.new

describe PryExceptionExplorer do

  before do
    PryExceptionExplorer.intercept { true }
    PryExceptionExplorer.enabled = true
  end

  after do
    O.clear
  end

  describe "Exceptions caught by Pry" do

    describe "internal exceptions (C-level)" do
      before do
        O.klass = Class.new do
          def alpha
            beta
          end
          def beta
            1 / 0
          end
        end
      end
      
      it 'should be able to enter internal exceptions' do
        redirect_pry_io(InputTester.new("O.klass.new.alpha",
                                        "enter-exception",
                                        "O.method_name = __method__",
                                        "exit")) do
          Pry.start
        end

        O.method_name.should == :beta
      end

      it 'should have the full call-stack available' do
        redirect_pry_io(InputTester.new("O.klass.new.alpha",
                                        "enter-exception",
                                        "show-stack",
                                        "exit"), out=StringIO.new) do
          Pry.start
        end

        out.string.should =~ /alpha/
      end
    end
    
    describe "enter-exception" do
      it  "should be able to enter an exception caught by pry" do
        # there are 3 types of situations where exception_explorer is invoked:
        # 1. when 'wrap' is used, i.e only exceptions that bubble to
        #    the top are intercepted.
        # 2. when exceptions are intercepted 'inline' (i.e dropped
        #    into pry directly from `raise` itself)
        # 3. exceptions are caught by pry and entered into by using
        #    the 'enter-exception' command
        # The case of 1. and 3. are actually very similar, but in
        # 3. the exception never bubbles to the top as it's caught by
        # pry instead; also in 3. a pry session is not started
        # automatically, the user must explicitly type
        # `enter-exception` to start the session.
        #
        # This test is for type 3.
        redirect_pry_io(InputTester.new("Ratty.new.ratty",
                                        "enter-exception",
                                        "O.method_name = __method__",
                                        "exit", StringIO.new)) do
          Pry.start
        end

        O.method_name.should == :toad
      end

      it  "should be able to enter an explicitly provided exception (even if _ex_ has changed)" do
        redirect_pry_io(InputTester.new("Ratty.new.ratty",
                                        "ex = _ex_",
                                        "AnotherException",
                                        "enter-exception ex",
                                        "O.method_name = __method__",
                                        "exit", StringIO.new)) do
          Pry.start
        end

        O.method_name.should == :toad
      end      

      it "should have access to exception's caller" do
        mock_pry("Ratty.new.ratty", "enter-exception", "show-stack", "exit").should =~ /toad.*?weasel.*?ratty/m
      end

      describe "enabled = false" do
        it 'should prevent moving into an exception' do
          old_e = PryExceptionExplorer.enabled
          PryExceptionExplorer.enabled = false

          mock_pry("Ratty.new.ratty", "enter-exception", "exit-all").should =~ /can't be entered/

          PryExceptionExplorer.enabled = old_e
        end
      end

      describe "continue-exception" do
        it 'should continue the exception' do
          o = OpenStruct.new
          def o.test_method
            raise "baby likes to raise an exception"
            self.value = 10
          end

          redirect_pry_io(InputTester.new("test_method",
                                          "enter-exception",
                                          "continue-exception",
                                          "exit-all")) do
            Pry.start(o)
          end

          o.value.should == 10
        end
      end

      describe "exit-exception" do
        it 'should display error message when exit-exception used outside of exception context' do
          mock_pry("exit-exception").should =~ /You are not in an exception!/
        end

       it  "should exit a nested exception and correctly pop FrameManagers" do
          redirect_pry_io(InputTester.new("Ratty.new.ratty",
                                          "enter-exception",
                                          "raise 'yo'",
                                          "enter-exception",
                                          "O.first_pry = _pry_",
                                          "O.first_count = PryStackExplorer.frame_managers(_pry_).count",
                                          "exit-exception",
                                          "O.second_pry = _pry_",
                                          "O.second_count = PryStackExplorer.frame_managers(_pry_).count",
                                          "exit-exception",
                                          "exit-all", StringIO.new)) do
            Pry.start(binding)
          end

          O.first_pry.should == O.second_pry
          O.first_count.should == 2
          O.second_count.should == 1
          PryStackExplorer.frame_managers(O.first_pry).count.should == 0
        end

        it  "should exit an exception and return to initial context" do
          redirect_pry_io(InputTester.new("Ratty.new.ratty",
                                          "O.initial_self = self",
                                          "enter-exception",
                                          "O.exception_self = self",
                                          "exit-exception",
                                          "O.return_self = self",
                                          "exit-all", StringIO.new)) do
            Pry.start(binding)
          end

          O.initial_self.should == self
          O.initial_self.should == O.return_self

          # actual exception context is Toad, as call chain is:
          # Ratty -> Weasel -> Toad (raise is here)
          O.exception_self.is_a?(Toad).should == true
        end


        describe "_ex_" do
          it  "should correctly update _ex_ to reflect exception context" do
            o = Object.new
            class << o
              attr_accessor :first_backtrace, :actual_first_backtrace
              attr_accessor :second_backtrace, :actual_second_backtrace
            end


            redirect_pry_io(InputTester.new("raise ArgumentError, 'yo yo'",
                                            "self.first_backtrace = _ex_.backtrace",
                                            "enter-exception",
                                            "self.actual_first_backtrace = _ex_.backtrace",
                                            "raise RuntimeError, 'bing bong'",
                                            "self.second_backtrace = _ex_.backtrace",
                                            "enter-exception",
                                            "self.actual_second_backtrace = _ex_.backtrace",
                                            "exit-all", StringIO.new)) do
              Pry.start(o)
            end

            o.first_backtrace.should == o.actual_first_backtrace
            o.second_backtrace.should == o.actual_second_backtrace

            # ensure nothing weird going on
            o.first_backtrace.should.not == o.second_backtrace
          end

          it  "should correctly restore _ex_ when exiting out of exceptions" do
            o = Object.new
            class << o
              attr_accessor :first_backtrace, :restored_first_backtrace
              attr_accessor :second_backtrace, :restored_second_backtrace
            end

            redirect_pry_io(InputTester.new("raise ArgumentError, 'yo yo'",
                                            "enter-exception",
                                            "self.first_backtrace = _ex_.backtrace",
                                            "raise RuntimeError, 'bing bong'",
                                            "enter-exception",
                                            "self.second_backtrace = _ex_.backtrace",
                                            "exit-exception",
                                            "exit-exception",
                                            "self.restored_first_backtrace = _ex_.backtrace",
                                            "exit-all", StringIO.new)) do
              Pry.start(o)
            end

            # just ensure nothing weird is happening (probably unnecessary)
            o.first_backtrace.should.not == o.second_backtrace

            o.first_backtrace.should == o.restored_first_backtrace
          end
        end

        describe "_pry_.backtrace" do
          it  "should correctly update _pry_.backtrace to reflect exception context" do
            o = Object.new
            class << o
              attr_accessor :first_backtrace, :ex_first_backtrace
              attr_accessor :second_backtrace, :ex_second_backtrace
            end

            redirect_pry_io(InputTester.new("raise ArgumentError, 'yo yo'",
                                            "enter-exception",
                                            "self.first_backtrace = _pry_.backtrace",
                                            "self.ex_first_backtrace = _ex_.backtrace",
                                            "raise RuntimeError, 'bing bong'",
                                            "enter-exception",
                                            "self.second_backtrace = _pry_.backtrace",
                                            "self.ex_second_backtrace = _ex_.backtrace",
                                            "exit-all", StringIO.new)) do
              Pry.start(o)
            end

            o.first_backtrace.should == o.ex_first_backtrace
            o.second_backtrace.should == o.ex_second_backtrace

            o.first_backtrace.should.not == o.second_backtrace
          end

          it  "should correctly restore _pry_.backtrace when exiting out of exceptions" do
            o = Object.new
            class << o
              attr_accessor :first_backtrace, :restored_first_backtrace
              attr_accessor :second_backtrace, :restored_second_backtrace
            end

            redirect_pry_io(InputTester.new("raise ArgumentError, 'yo yo'",
                                            "enter-exception",
                                            "self.first_backtrace = _pry_.backtrace",
                                            "raise RuntimeError, 'bing bong'",
                                            "enter-exception",
                                            "self.second_backtrace = _pry_.backtrace",
                                            "exit-exception",
                                            "self.restored_first_backtrace = _pry_.backtrace",
                                            "exit-all", StringIO.new)) do

              Pry.start(o)
            end

            o.first_backtrace.should.not == o.second_backtrace
            o.first_backtrace.should == o.restored_first_backtrace
          end
        end


      end
    end
  end
end

Object.send(:remove_const, :O)
