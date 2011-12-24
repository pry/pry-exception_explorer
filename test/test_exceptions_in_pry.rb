require 'helper'

describe PryExceptionExplorer do

  describe "Exceptions caught by Pry" do
    describe "enter-exception" do
      it  "should be able to enter an exception caught by pry" do

        # forcing the test to fail, if i remove this line but keep the
        # 'fdfdsf' junk below, this test still passes
        junkjunk

        PryExceptionExplorer.intercept { true }

        # lol ok JUNK seems to be ok, something weird going on
        fdfdfsf

        PryExceptionExplorer.wrap_active = false

        # this test should only pass if wrap_active == true, however
        # it's passing even with wrap_active == false, something fishy
        # is going on, hence forcing it to fail so i remember to look at it later
        PryExceptionExplorer.wrap_active.should == true

        mock_pry("Ratty.new.ratty", "enter-exception", "show-stack", "exit").should =~ /toad.*?weasel.*?ratty/m
      end
    end
  end
end
