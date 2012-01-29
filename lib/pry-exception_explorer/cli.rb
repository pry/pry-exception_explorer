Pry::CLI.add_options do

  on :w, :wrap, "Run the script wrapped by the exception explorer", true do |file|
    PryExceptionExplorer.wrap do
      require file
    end

    exit
  end

  on "c-exceptions", "Experimental hook for C exceptions" do
    require 'pry-exception_explorer/shim_builder'

    binary_name = "lib_overrides.#{PryExceptionExplorer::ShimBuilder::Dyname}"

    if !File.exists? File.join PryExceptionExplorer::ShimBuilder.dir, binary_name
      puts "First run, building shim"
      PryExceptionExplorer::ShimBuilder.compile
      puts "Hopefully built...!"
    end

    if RUBY_PLATFORM =~ /darwin/
      ENV['DYLD_FORCE_FLAT_NAMESPACE'] = "1"
      ENV['DYLD_INSERT_LIBRARIES'] = File.join PryExceptionExplorer::ShimBuilder.dir, binary_name
    else
      ENV['LD_PRELOAD'] = File.join PryExceptionExplorer::ShimBuilder.dir, binary_name
    end

    exec("pry #{(ARGV - ["--c-exceptions"]).join(' ')}")
  end
end
