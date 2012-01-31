pry-exception_explorer
===========

(C) John Mair (banisterfiend) 2011

_Enter the context of exceptions_

`pry-exception_explorer` is an interactive error console for Ruby 1.9.2+ inspired by the [Hammertime](https://github.com/avdi/hammertime) 
gem, which was in turn inspired by consoles found in the Lisp and Smalltalk environments.

Using `pry-exception_explorer` we can automatically pull up a [Pry](http://pry.github.com) session at the point an exception arises and use `Pry` 
to inspect the state there to debug (and fix) the problem. We also get access to the entire call stack of the exception and can walk the stack to interactively examine the state in
parent frames.

* Install the [gem](https://rubygems.org/gems/pry-exception_explorer): `gem install pry-exception_explorer`
* Read the [documentation](http://rdoc.info/github/banister/pry-exception_explorer/master/file/README.md)
* See the [source code](http://github.com/banister/pry-exception_explorer)

Example: Example description
--------

Example preamble

    puts "example code"

Features and limitations
-------------------------

Feature List Preamble

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
