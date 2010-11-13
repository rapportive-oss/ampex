require 'blankslate'

# The Ampex library provides a metavariable X that can be used in conjunction
# with the unary ampersand to create anonymous blocks in a slightly more
# readable way than the default. It was inspired by the clever `Symbol#to_proc`
# method which handles the most common case very elegantly, and discussion with
# Sam Stokes who implemented an earlier version of the idea.
# 
# At its simplest, &X can be used as a drop-in replacement for
# `Symbol#to_proc`:
# 
#     [1,2,3].map &X.to_s
#       # => ["1", "2", "3"]
# 
# However the real strength in the library comes from allowing you to call
# methods:
# 
#     [1,"2",3].select &X.is_a?(String)
#       # => ["2"]
# 
# And, as everything in ruby is a method, create readable expressions without
# the noise of a one-argument block:
# 
#     [{1 => 2}, {1 => 3}].map &X[1]
#       # => [2, 3]
# 
#     [1,2,3].map &-X
#       # => [-1, -2, -3]
# 
#     ["a", "b", "c"].map &(X * 2)
#       # => ["aa", "bb", "cc"]
# 
# As an added bonus, the effect is transitive — you can chain method calls:
# 
#     [1, 2, 3].map &X.to_f.to_s
#       # => ["1.0", "2.0", "3.0"]
# 
# There are two things to watch out for:
# 
# Firstly, &X can only appear on the left:
# 
#     [1, 2, 3].map &(X + 1) 
#       # => [2, 3, 4]
# 
#     [1, 2, 3].map &(1 + X) # WRONG
#       # => TypeError, "coerce must return [x, y]"
# 
#     [[1],[2]].map &X.concat([2])
#       # => [[1, 2], [2, 2]]
# 
#     [[1],[2]].map &[2].concat(X) # WRONG
#       # => TypeError, "Metavariable#to_ary should return Array"
# 
# Secondly, the arguments or operands will only be evaluated once, and not
# every time:
# 
#    i = 0 [1, 2].map &(X + (i += 1)) # WRONG
#      # => [2, 3]
# 
#    i = 0 [1, 2].map{ |x| x + (i += 1) }
#      # => [2, 4]
# 
# For bug-fixes or enhancements, please contact the author:
#   Conrad Irwin <conrad.irwin@gmail.com>
# 
# This library is copyrighted under the MIT license, see LICENSE.MIT.

class Metavariable < BlankSlate 
  def initialize(parent=nil, &block)
    @block = block
    @parent = parent
  end

  def method_missing(name, *args, &block)
    Metavariable.new(self) { |x| x.send(name, *args, &block) }
  end

  def to_proc
    lambda do |x|
      if @block
        x = @parent.to_proc.call(x) if @parent
        @block.call x
      else
        x
      end
    end
  end
end

X = Metavariable.new
