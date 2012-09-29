require 'helper'

describe PryExceptionExplorer do

  describe "normal raise behaviour (EE.enabled = false)" do
    before do
      EE.enabled = false
    end

    it 'should raise the exception that was raised' do
      begin
        raise ArgumentError
      rescue => ex
        ex.is_a?(ArgumentError).should == true
      end
    end

    it 'should keep message' do
      begin
        raise ArgumentError, "hello"
      rescue => ex
        ex.message.should == "hello"
      end
    end

    it 'should implicitly re-raise rescued exceptione' do
      begin
        raise ArgumentError
      rescue => ex
        begin
          raise
        rescue => ex2
          ex2.is_a?(ArgumentError).should == true
        end
      end
    end

    it 'should implicitly raise RuntimeError (when not inside rescue)' do
      begin
        raise
      rescue => ex
        ex.is_a?(RuntimeError).should == true
      end
    end

    it 'should re-raise raised rescued exception' do
      begin
        raise ArgumentError
      rescue => ex
        begin
          raise ex
        rescue
          ex.is_a?(ArgumentError).should == true
        end
      end
    end
  end

  describe "raise behaviour AFTER interception (EE.enabled = true)" do
    before do
      Pry.config.hooks.add_hook(:when_started, :save_caller_bindings, WhenStartedHook)
      Pry.config.hooks.add_hook(:after_session, :delete_frame_manager, AfterSessionHook)

      EE.enabled = true
      EE.intercept(ArgumentError)
      Pry.config.input = StringIO.new("exit-all\n")
    end

    after do
      Pry.config.hooks.delete_hook(:when_started, :save_caller_bindings)
      Pry.config.hooks.delete_hook(:after_session, :delete_frame_manager)
    end

    it 'should raise the exception that was raised' do
      begin
        raise ArgumentError
      rescue => ex
        ex.is_a?(ArgumentError).should == true
      end
    end

    it 'should keep message' do
      begin
        raise ArgumentError, "hello"
      rescue => ex
        ex.message.should == "hello"
      end
    end

    it 'should implicitly re-raise rescued exceptione' do
      begin
        raise ArgumentError
      rescue => ex
        begin
          raise
        rescue => ex2
          ex2.is_a?(ArgumentError).should == true
        end
      end
    end

    it 'should implicitly raise RuntimeError (when not inside rescue)' do
      begin
        raise
      rescue => ex
        ex.is_a?(RuntimeError).should == true
      end
    end

    it 'should re-raise raised rescued exception' do
      begin
        raise ArgumentError
      rescue => ex
        begin
          raise ex
        rescue
          ex.is_a?(ArgumentError).should == true
        end
      end
    end





  end
end


