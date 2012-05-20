The Ampex (`&X`) library provides a Metavariable X that can be used in conjunction with the unary ampersand to create anonymous blocks in a slightly more readable way than the default. It was inspired by the clever `Symbol#to_proc` method which handles the most common case very elegantly, and discussion with Sam Stokes about creating lazy enumerators in ruby.

Usage
-----

At its simplest, `&X` can be used as a drop-in replacement for `Symbol#to_proc`:

    [1,2,3].map &X.to_s
      # => ["1", "2", "3"]

However the real strength in the library comes from allowing you to call methods with arguments:

    [1,"2",3].select &X.is_a?(String)
      # => ["2"]

And to chain method calls:

    [1, 2, 3].map &X.to_f.to_s
      # => ["1.0", "2.0", "3.0"]

As everything in Ruby is a method call, you can create readable expressions without the noise of a one-argument block:

    [{1 => 2}, {1 => 3}].map &X[1]
      # => [2, 3]

    [1,2,3].map &-X
      # => [-1, -2, -3]

    ["a", "b", "c"].map &(X * 2)
      # => ["aa", "bb", "cc"]

You can use this in any place a block is expected, for example to create a lambda:

    normalizer = lambda &X.to_s.downcase
    normalizer.call :HelloWorld
      # => "helloworld"

Gotchas
-------

There are a few things to watch out for:

Firstly, `&X` can only appear on the left:

    [1, 2, 3].map &(X + 1)
      # => [2, 3, 4]

    [1, 2, 3].map &(1 + X) # WRONG
      # => TypeError, "coerce must return [x, y]"

    [[1],[2]].map &X.concat([2])
      # => [[1, 2], [2, 2]]

    [[1],[2]].map &[2].concat(X) # WRONG
      # => TypeError, "Metavariable#to_ary should return Array"

Secondly, other arguments or operands will only be evaluated once, and not every time:

    i = 0
    [1, 2].map &(X + (i += 1)) # WRONG
      # => [2, 3]

    i = 0
    [1, 2].map{ |x| x + (i += 1) }
      # => [2, 4]

Epilogue
--------

`&X` has been tested on MRI ruby 1.8.6, 1.8.7, 1.9.2, 1.9.3, jruby, and rubinius.

For bug-fixes or enhancements, please contact the author: Conrad Irwin <conrad.irwin@gmail.com>

For an up-to-date version, try <https://github.com/rapportive-oss/ampex>

This library is copyrighted under the MIT license, see LICENSE.MIT for details.


Backwards compatibility breakages
---------------------------------

Between version 1.2.1 and version 2.0.0, the support for assignment operations was removed from
ampex. These had a very non-obvious implementation, and it was impossible to support
assigning of falsey values; and did not work on rubinius.

See also
--------

* <https://cirw.in/blog/ampex> — a blog post that describes the ideas.
* <https://github.com/danielribeiro/RubyUnderscore> — which uses an underscore in place of `&X` and works by rewriting the syntax tree.
* <https://gist.github.com/1224361> — a patch for Rubinius that enables the underscore in a similar way.
* <http://blog.railsware.com/2012/03/13/ruby-2-0-enumerablelazy/> — The upcoming lazy enumerable support for Ruby 2.0.
