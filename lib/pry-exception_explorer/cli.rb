Pry::CLI.add_options do

  on :w, :wrap, "Run the script wrapped by the exception explorer", true do |file|
    require 'pry-exception_explorer'

    PryExceptionExplorer.wrap do
      require file
    end

    exit
  end

end
