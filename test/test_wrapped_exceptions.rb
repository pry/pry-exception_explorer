require 'helper'

#require 'pry-exception_explorer/exception_wrap'

describe PryExceptionExplorer do

  before do
    Pry.config.input = StringIO.new("exit :caught\n")
  end

  describe "PryExceptionExplorer.wrap" do
    it 'should catch a specified exception' do
 #     PryExceptionExplorer.wrap do
#       raise "hi"
  #    end
    end
  end
end
