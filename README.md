pry-exception_explorer
===========

(C) John Mair (banisterfiend) 2011

_Enter the context of exceptions_

`pry-exception_explorer` is an interactive error console for MRI Ruby 1.9.2+ inspired by the [Hammertime](https://github.com/avdi/hammertime)
gem, which was in turn inspired by consoles found in the Lisp and Smalltalk environments. `pry-exception_explorer` is a plugin
for the [Pry REPL](http://pry.github.com). 

**Note**, like the hammertime gem, `pry-exception_explorer` can only really intercept exceptions that are explicitly raised (using the `raise` method) from Ruby code. 
This means that exceptions raised by syntax errors or from code such as `1/0` cannot be intercepted. Though experimental support for intercepting such deep (c-level) exceptions is provided by invoking with `pry --c-exceptions`.

Using `pry-exception_explorer` we can automatically pull up a [Pry](http://pry.github.com) session at the point an exception arises and use `Pry`
to inspect the state there to debug (and fix) the problem. We also get access to the entire call stack of the exception and can walk the stack to interactively examine the state in
parent frames (using [pry-stack_explorer](https://github.com/pry/pry-stack_explorer)).

**Watch the mini-screencast:** http://vimeo.com/36061298

* Install the [gem](https://rubygems.org/gems/pry-exception_explorer): `gem install pry-exception_explorer`
* Read the [documentation](http://rdoc.info/github/banister/pry-exception_explorer/master/file/README.md)
* See the [source code](http://github.com/banister/pry-exception_explorer)
* See the [**WIKI**](https://github.com/pry/pry-exception_explorer/wiki) for in-depth usage information.

Also look at the [plymouth](https://github.com/banister/plymouth) project which utilizes `pry-exception_explorer` to intercept test failures.

Example:
--------

In the Ruby file:

```ruby
require 'pry-exception_explorer'

EE.enabled = true
EE.intercept(ArgumentError)

def alpha
  name = "john"
  beta
  puts name
end

def beta
  x = "john"
  gamma(x)
end

def gamma(x)
  raise ArgumentError, "x must be a number!" if !x.is_a?(Numeric)
  puts "2 * x = #{2 * x}"
end

alpha

```

The following session starts up:

```ruby
Frame number: 0/4
Frame type: method

From: /Users/john/ruby/projects/pry-exception_explorer/examples/example_inline.rb @ line 23 in Object#gamma:

    18:   x = "john"
    19:   gamma(x)
    20: end
    21:
    22: def gamma(x)
 => 23:   raise ArgumentError, "x must be a number!" if !x.is_a?(Numeric)
    24:   puts "2 * x = #{2 * x}"
    25: end
    26:
    27: alpha

[1] (pry) main: 0> x
=> "john"
[2] (pry) main: 0> x = 7
=> 7
[3] (pry) main: 0> continue-exception
```

Since we fixed the problem (invalid type for `x` local) we can `continue-exception`, and have the method continue with the
amended `x`:

**PROGRAM OUTPUT:**

>> 2 * x = 14

>> john

Features and limitations
-------------------------

### Features

* Puts you in context of exception.
* Makes entire call stack accessible (useful for drilling down to precise cause of error).
* Allows you to 'continue' from exception, recovering from error (`continue-exception` command)
* Has limited/experimental ability to intercept exceptions that arise from C code (use `pry --c-exceptions` to enable).
* Let's you assert over state of entire stack when determining whether an exception should be intercepted.
* Let's you start the session on any stack frame.

### Limitations

* Only works on Ruby 1.9.2+ (including 1.9.3) MRI.
* Limited support for `C` exceptions -- only some exceptions that arise from C code are caught.

Contact
-------

Problems or questions contact me at [github](http://github.com/banister)


License
-------

(The MIT License)

Copyright (c) 2011 John Mair (banisterfiend)

Permission is hereby granted, free of charge, to any person obtaining
a copy of this software and associated documentation files (the
'Software'), to deal in the Software without restriction, including
without limitation the rights to use, copy, modify, merge, publish,
distribute, sublicense, and/or sell copies of the Software, and to
permit persons to whom the Software is furnished to do so, subject to
the following conditions:

The above copyright notice and this permission notice shall be
included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED 'AS IS', WITHOUT WARRANTY OF ANY KIND,
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
