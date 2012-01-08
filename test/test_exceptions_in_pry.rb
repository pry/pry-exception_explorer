require 'helper'

O = OpenStruct.new

describe PryExceptionExplorer do

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
        PryExceptionExplorer.intercept { true }
        redirect_pry_io(InputTester.new("Ratty.new.ratty",
                                        "enter-exception",
                                        "O.method_name = __method__",
                                        "exit", StringIO.new)) do
          Pry.start
        end

        O.method_name.should == :toad
      end

      it "should have access to exception's caller" do
        PryExceptionExplorer.intercept { true }
        mock_pry("Ratty.new.ratty", "enter-exception", "show-stack", "exit").should =~ /toad.*?weasel.*?ratty/m
      end

       describe "exit-exception" do
        it  "should exit an exception and return to initial context" do
          PryExceptionExplorer.intercept { true }
          redirect_pry_io(InputTester.new("Ratty.new.ratty",
                                          "O.initial_self = self",
                                          "enter-exception",
                                          "O.exception_self = self",
                                          "exit-exception",
                                          "O.return_self = self",
                                          "exit", StringIO.new)) do
            Pry.start(0)
         end

          O.initial_self.should == 0
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
