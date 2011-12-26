require 'helper'

describe PryExceptionExplorer do

  describe "Exceptions caught by Pry" do
    describe "enter-exception" do
      it  "should be able to enter an exception caught by pry" do

        # FIXME: this should actually be set to true, not false, but
        # it hangs tests when it's set to true, so we temporarily set
        # it false here (until we refactor later on)
        PryExceptionExplorer.intercept { false }

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

        # FIXME: this test passes when wrap_active is set to true, but we set
        # it to false here so we remember to refactor the
        # exception_explorer code base to include this.
        PryExceptionExplorer.wrap_active = false

        # let's force the test to fail here so we remember about the refactor
        PryExceptionExplorer.wrap_active.should == true

        mock_pry("Ratty.new.ratty", "enter-exception", "show-stack", "exit").should =~ /toad.*?weasel.*?ratty/m
      end
    end
  end
end
