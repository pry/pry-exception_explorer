Pry::CLI.add_options do

  on :w, :wrap, "Run the provided FILE wrapped by the exception explorer", true do |file|
    require 'pry-exception_explorer'
    PryExceptionExplorer.wrap do
      load file
    end

    exit
  end

  on "c-exceptions", "Experimental hook for C exceptions" do
    exec("pry-shim pry --no-pager #{(ARGV - ["--c-exceptions"]).join(' ')}")
  end
end
