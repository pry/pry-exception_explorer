require 'helper'

EE.instance_eval do
  alias original_enter_exception_inline enter_exception_inline
end

def EE.exception_intercepted?
  @exception_intercepted
end

EE.instance_eval do
  @exception_intercepted = false
end

def EE.enter_exception_inline(ex)
  @exception_intercepted = true
  EE::CONTINUE_INLINE_EXCEPTION
end

describe PryExceptionExplorer do

  before do
    @o = Object.new
    def @o.ratty() weasel() end
    def @o.weasel() toad() end
    def @o.toad() raise "toad hall" end
  end

  after do
    EE.instance_eval do
      @exception_intercepted = false
    end
  end

  describe "PryExceptionExplorer#intercept" do
    describe "method_name" do
      it  "should intercept exception based on first frame's method name" do
        EE.intercept { |frame, ex| frame.method_name == :toad }
        @o.toad
        EE.exception_intercepted?.should == true
      end

      it  "should NOT intercept exception if method name doesn't match" do
        EE.intercept { |frame, ex| frame.method_name == :ratty }
        begin
          @o.toad
        rescue Exception => ex
          ex.is_a?(RuntimeError).should == true
        end
        EE.exception_intercepted?.should == false
      end
      
    end
    
  end
end
