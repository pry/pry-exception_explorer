module PryExceptionExplorer
  class Intercept

    # @return [Proc] The predicate block that determines if
    #   interception takes place.
    attr_reader :block

    # @return [Fixnum] Number of frames to skip when session starts.
    attr_reader :skip_num

    # @return [Proc] The block that defines the frames to skip.
    attr_reader :skip_while_block

    # @return [Proc] The block that determines when to stop skipping frames.
    attr_reader :skip_until_block

    # @return [Boolean] Whether this intercept object is active
    #   If it's inactive then calling it will always return `false`
    #   regardless of content inside block.
    def active?() !!@active end

    # Disable the intercept object.
    # @return [PryExceptionExplorer::Intercept] The receiver
    def disable!() tap { @active = false } end

    # Enable if the intercept object.
    # @return [PryExceptionExplorer::Intercept] The receiver
    def enable!() tap { @active = true } end

    # @param [Fixnum] num Number of frames to skip when session
    #   starts.
    # @return [PryExceptionExplorer::Intercept] The receiver
    def skip(num) tap { @skip_num = num } end

    # @yield [lazy_frame] The block that defines the frames to
    #  skip. The Pry session will start on the first frame for which
    #  this block evalutes to `false`.
    # @yieldparam [PryExceptionExplorer::LazyFrame] lazy_frame
    # @yieldreturn [Boolean]
    # @return [PryExceptionExplorer::Intercept] The receiver
    def skip_while(&block) tap { @skip_while_block = block } end

    # @yield [lazy_frame] The block that determines when to stop skipping frames.
    #  The Pry session will start on the first frame for which
    #  this block evalutes to `true`.
    # @yieldparam [PryExceptionExplorer::LazyFrame] lazy_frame
    # @yieldreturn [Boolean]
    # @return [PryExceptionExplorer::Intercept] The receiver
    def skip_until(&block) tap { @skip_until_block = block } end

    # @param [Boolean] should_recurse Whether to intercept exceptions
    #   raised inside the session.
    # @return [PryExceptionExplorer::Intercept] The receiver
    def intercept_recurse(should_recurse) tap { @intercept_recurse = should_recurse } end

    # @return [Boolean] Whether exceptions raised inside the session
    #   will be intercepted.
    def intercept_recurse?() !!@intercept_recurse end

    def initialize(block)
      skip(0)
      intercept_recurse(false)

      @block  = block
      @active = true
    end

    # Invoke the associated block for this
    # `PryExceptionExplorer::Intercept` object. Note that the block is
    # not invoked if the intercept object is inactive.
    # @param [Array] args The parameters to
    # @return [Boolean] Determines whether a given exception should be intercepted.
    def call(*args)
      active? && @block.call(*args)
    end
  end
end
