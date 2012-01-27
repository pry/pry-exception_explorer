module PryExceptionExplorer
  class Intercept
    attr_accessor :skip
    attr_reader :block

    def initialize(block, options={})
      options = {
        :skip => 0
      }.merge!(options)

      @block = block
      @skip = options[:skip]
    end

    def call(*args)
      @block.call(*args)
    end
  end
end
