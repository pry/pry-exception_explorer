Pry::CLI.add_options do
  on :w, :wrap, "Run the script wrapped by the exception explorer", true do |file|
    PryExceptionExplorer.wrap do
      require file
    end
  end
end.process_options do |opts|
  if opts.present?(:cirwin) && opts.present?(:butterfly)
    puts "got both cirwin and butterfly"
  elsif opts.present?(:cirwin)
    puts "just got cirwin"
  elsif opts.present?(:butterfly)
    puts "just got butterfly"
  else
    puts "got neither cirwin or buttefly lolz"
  end
end
