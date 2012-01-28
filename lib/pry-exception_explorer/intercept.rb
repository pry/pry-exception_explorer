module PryExceptionExplorer
  class Intercept

    # @return [Fixnum] Number of frames to skip when session starts.
    attr_accessor :skip

    # @return [Boolean] Whether to intercept exceptions raised inside the session.
    attr_accessor :intercept_recurse
    alias_method :intercept_recurse?, :intercept_recurse

    # @return [Boolean] Whether this intercept object is active
    #   If it's inactive then calling it will always return `false`
    #   regardless of content inside block.
    def active?() @active end

    # Disable the intercept object.
    def disable!() @active = false end

    # Enable if the intercept object.
    def enable!() @active = true end
    
    # @return [Proc] The predicate block that determines if
    #   interception takes place.
    attr_reader :block

    def initialize(block, options={})
      options = {
        :skip              => 0,
        :intercept_recurse => false
      }.merge!(options)

      @block = block
      @skip  = options[:skip]
      @intercept_recurse = options[:intercept_recurse]

      @active = true
    end

    def call(*args)
      active? && @block.call(*args)
    end
  end
end
