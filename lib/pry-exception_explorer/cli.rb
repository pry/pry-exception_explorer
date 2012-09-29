require 'pry-exception_explorer'

Pry::CLI.add_options do
  on :w, :wrap, "Run the provided FILE wrapped by exception explorer", :argument => true do |file|
    PryExceptionExplorer.enabled = false
    PryExceptionExplorer.wrap do
      load file
    end
    
    exit
  end
end
