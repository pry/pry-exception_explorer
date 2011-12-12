# pry-exception_explorer.rb
# (C) John Mair (banisterfiend); MIT license

require "pry-exception_explorer/version"
require "pry"

class Exception
  attr_accessor :exception_call_stack
end

class Object
  def raise(exception = RuntimeError, string = nil, array = caller)
    if exception.is_a?(String)
      string = exception
      exception = RuntimeError
    end

    ex = exception.exception(string)
    ex.set_backtrace(array)
    ex.exception_call_stack = binding.callers.tap(&:shift)

    super(ex)
  end
end

PryExceptionExplorer::Commands = Pry::CommandSet.new do

  command "enter-exception", "Enter the context of the last exception" do
    PryStackExplorer.push_and_create_frame_manager(_pry_.last_exception.exception_call_stack, _pry_)
    PryStackExplorer.frame_manager(_pry_).refresh_frame
  end

  command "exit-exception", "Leave the context of the current exception." do
    PryStackExplorer.pop_frame_manager(_pry_)
    PryStackExplorer.frame_manager(_pry_).refresh_frame
  end
end

Pry.config.commands.import PryExceptionExplorer::Commands
