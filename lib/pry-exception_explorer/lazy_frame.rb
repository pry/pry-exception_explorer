module PryExceptionExplorer
  class LazyFrame

    # we need to jump over a few irrelevant frames to begin with
    START_FRAME_OFFSET = 5
    
    def initialize(frame, frame_counter = 0)
      @frame         = frame
      @frame_counter = frame_counter
    end

    def raw_frame
      @frame
    end

    def klass
      @frame.eval("self.class")
    end

    def self
      @frame.eval("self")
    end

    def method_name
      @frame.eval("__method__")
    end

    def prev
      LazyFrame.new(binding.of_caller(@frame_counter + START_FRAME_OFFSET), @frame_counter + 1)
    end
  end
end
