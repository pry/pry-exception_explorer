# pry-exception_explorer.rb
# (C) John Mair (banisterfiend); MIT license

require 'pry-stack_explorer'
require "pry-exception_explorer/version"
require "pry"

if RUBY_VERSION =~ /1.9/
  require 'continuation'
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
    ex = _pry_.last_exception
    if ex && ex.exception_call_stack
      PryStackExplorer.create_and_push_frame_manager(_pry_.last_exception.exception_call_stack, _pry_)
      PryStackExplorer.frame_manager(_pry_).user[:exception] = _pry_.last_exception
      PryStackExplorer.frame_manager(_pry_).refresh_frame
    elsif ex
      output.puts "Current exception can't be entered! (perhaps a C exception)"
    else
      output.puts "No exception to enter!"
    end
  end

  command "exit-exception", "Leave the context of the current exception." do
    fm = PryStackExplorer.frame_manager(_pry_)
    if fm && fm.user[:exception]
      PryStackExplorer.pop_frame_manager(_pry_)
      PryStackExplorer.frame_manager(_pry_).refresh_frame
    else
      output.puts "You are not in an exception!"
    end
  end

  command "continue-exception", "Attempt to continue the current exception." do
    fm = PryStackExplorer.frame_manager(_pry_)

    if fm && fm.user[:exception] && fm.user[:exception].continuation
      PryStackExplorer.pop_frame_manager(_pry_)
      fm.user[:exception].continue
    else
      output.puts "No exception to continue!"
    end
  end

end

Pry.config.commands.import PryExceptionExplorer::Commands
