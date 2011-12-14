# pry-exception_explorer.rb
# (C) John Mair (banisterfiend); MIT license

require 'pry-stack_explorer'
require "pry-exception_explorer/version"
require "pry"

if RUBY_VERSION =~ /1.9/
  require 'continuation'
end

Pry.config.hooks.delete_hook(:when_started, :save_caller_bindings)

module PryExceptionExplorer
  def self.wrap
    yield
  rescue Exception => ex
    Pry.config.hooks.add_hook(:when_started, :setup_exception_context) do |binding_stack, _pry_|
      binding_stack.replace([ex.exception_call_stack.first])
      PryStackExplorer.push_and_create_frame_manager(ex.exception_call_stack, _pry_)
      PryStackExplorer.frame_manager(_pry_).user[:exception] = ex
    end

    pry
  end
end

class Exception
  NoContinuation = Class.new(StandardError)

  attr_accessor :continuation
  attr_accessor :exception_call_stack

  def continue
    raise NoContinuation unless continuation.respond_to?(:call)
    continuation.call
  end
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

    callcc do |cc|
      ex.continuation = cc
      super(ex)
    end
  end
end

PryExceptionExplorer::Commands = Pry::CommandSet.new do

  command "enter-exception", "Enter the context of the last exception" do
    PryStackExplorer.push_and_create_frame_manager(_pry_.last_exception.exception_call_stack, _pry_)
    PryStackExplorer.frame_manager(_pry_).user[:exception] = _pry_.last_exception
    PryStackExplorer.frame_manager(_pry_).refresh_frame
  end

  command "exit-exception", "Leave the context of the current exception." do
    PryStackExplorer.pop_frame_manager(_pry_)
    PryStackExplorer.frame_manager(_pry_).refresh_frame
  end

  command "continue-exception", "Attempt to continue the current exception." do
    ex = PryStackExplorer.frame_manager(_pry_).user[:exception]

    if ex && ex.continuation
      PryStackExplorer.pop_frame_manager(_pry_)
      ex.continue
    else
      output.puts "No exception to continue!"
    end
  end

end

Pry.config.commands.import PryExceptionExplorer::Commands
