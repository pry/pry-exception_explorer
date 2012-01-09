require 'helper'

O = OpenStruct.new

describe PryExceptionExplorer do

  before do
    PryExceptionExplorer.intercept { true }
    PryExceptionExplorer.wrap_active = true
  end

  after do
    O.clear
  end

  describe "Exceptions caught by Pry" do
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

      it "should have access to exception's caller" do
        mock_pry("Ratty.new.ratty", "enter-exception", "show-stack", "exit").should =~ /toad.*?weasel.*?ratty/m
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
      end
    end
  end
end

Object.send(:remove_const, :O)
