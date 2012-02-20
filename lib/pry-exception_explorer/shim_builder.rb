require 'rbconfig'
require 'fileutils'

module PryExceptionExplorer
  CompileError = Class.new(StandardError)

  module ShimBuilder
    class << self
      attr_reader :dir, :file
    end

    @dir = File.expand_path("~/.pry-exception_explorer/#{RUBY_VERSION}")
    @file = File.join(@dir, "raise_shim.c")

    if RUBY_PLATFORM =~ /darwin/
      Dyname = "dylib"
    else
      Dyname = "so"
    end

    ShimCode = <<-EOF
#include <stdio.h>
#include <dlfcn.h>
#include <stdlib.h>
#include <unistd.h>
#include <ruby.h>

void
rb_raise(VALUE exc, const char *fmt, ...)
{
    va_list args;
    VALUE mesg;

    va_start(args, fmt);
    mesg = rb_vsprintf(fmt, args);
    va_end(args);
    rb_funcall(rb_cObject, rb_intern("raise"), 2, exc, mesg);
}

void
rb_name_error(ID id, const char *fmt, ...)
{
  rb_funcall(rb_cObject, rb_intern("raise"), 2, rb_eNameError, rb_str_new2("hooked exception (pry)"));
}

EOF

    def self.create_directory_and_source_file
      FileUtils.mkdir_p(@dir)
      File.open(@file, 'w') do |f|
        f.puts(ShimCode)
      end
    end

    def self.compile
      create_directory_and_source_file

      # -L
      lib_dir = RbConfig::CONFIG['libdir']

      # -I
      arch_include = File.join RbConfig::CONFIG['includedir'], "ruby-1.9.1",  RbConfig::CONFIG['arch']
      backward_include = File.join RbConfig::CONFIG['includedir'], "ruby-1.9.1",  "ruby/backward"
      ruby191_include = File.join RbConfig::CONFIG['includedir'], "ruby-1.9.1"

      if RUBY_PLATFORM =~ /darwin/
        compile_line = "gcc -Wall -L#{lib_dir} -lruby -I#{arch_include}  -I#{backward_include} -I#{ruby191_include} -o lib_overrides.dylib -dynamiclib #{@file}"
      else
        compile_line = "gcc -Wall -O2 -fpic -shared -ldl -g -I#{arch_include}  -I#{backward_include} -I#{ruby191_include} -o lib_overrides.so #{@file}"
      end

      FileUtils.chdir @dir do
        if !system(compile_line)
          raise CompileError, "There was a problem building the shim, aborted!"
        end
      end

    end
  end
end

