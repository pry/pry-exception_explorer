module PryExceptionExplorer
  class LazyFrame
    class NullFrame
      def klass() nil end
      def self() nil end
      def method_name() nil end
      def prev() self end
    end

    # we need to jump over a few irrelevant frames to begin with
    START_FRAME_OFFSET = 6

    def initialize(frame, frame_counter = 0, call_stack = nil)
      @frame         = frame
      @frame_counter = frame_counter
      @call_stack    = call_stack
    end

    # @return [Class] The class of the `self` of the frame.
    def klass
      @frame.eval("self.class")
    end

    # @return [Object] The object context of the frame (the `self`).
    def self
      @frame.eval("self")
    end

    # @return [Symbol, nil] The name of the active method in the frame (or `nil`)
    def method_name
      @frame.eval("__method__")
    end

    # @return [LazyFrame] The caller frame.
    def prev
      if @call_stack
        if @frame_counter < (@call_stack.size - 1)
          LazyFrame.new(@call_stack[@frame_counter + 1], @frame_counter + 1, @call_stack)
        else
          NullFrame.new
        end
      else
        LazyFrame.new(binding.of_caller(@frame_counter + START_FRAME_OFFSET), @frame_counter + 1)
      end
    end
  end
end
