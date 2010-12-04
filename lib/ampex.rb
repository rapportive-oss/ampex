require 'blankslate'

# Copyright 2010 Conrad Irwin <conrad.irwin@gmail.com> MIT License
#
# For detailed usage notes, please see README.markdown
#
class Metavariable < BlankSlate

  # When you pass an argument with & in ruby, you're actually calling #to_proc
  # on the object. So it's Symbol#to_proc that makes the &:to_s trick work,
  # and Metavariable#to_proc that makes &X work.
  attr_reader :to_proc

  def initialize(&block)
    @to_proc = block || lambda{|x| x}
  end

  # Each time a method is called on a Metavariable, we want to create a new
  # Metavariable that is like the last but does something more.
  #
  # The end result of calling X.one.two will be like:
  #
  # lambda{|x|
  #   (lambda{|x|
  #     (lambda{|x| x}).call(x).one
  #   }).call(x).two
  # }
  #
  def method_missing(name, *args, &block)
    mv = Metavariable.new { |x| @to_proc.call(x).send(name, *args, &block) }
    Metavariable.temporarily_monkeypatch(args.last, :to_proc) { mv.to_proc } if name.to_s =~ /[^!=<>]=$/
    mv
  end

  private

  # In order to support assignment via &X (expressions of the form &X['one'] = 2),
  # we need to add 2.to_proc (because assignment in ruby always returns the operand)
  #
  # Luckily, we only need to do this for a very short time.
  #
  # When given an expression such as:
  #
  #  ary.map(&X[args(a)] = :two)
  #
  # the order of execution is:
  #  args(a)
  #  X[_] = :two    \_ need to patch here
  #  :two.to_proc  _/  and  un-patch here
  #  ary.map &_
  #
  # We go to some lengths to ensure that, providing the & and the X are adjacent,
  # it's not possible to get different behaviour in the rest of the program; despite
  # the temporary mutation of potentially global state.
  #
  # We can't really do anything if the & has been split from the X, consider:
  #
  #   assigner = (X[0] = :to_i)
  #   assigner == :to_i
  #     # => true
  #   [1,2,3].map(&:to_i)
  #     # => NoMethodError: undefined method `[]=' for 1:Fixnum
  #
  # Just strongly encourage use of:
  #   assigner = lambda &X = :to_i
  #   assigner == :to_i
  #     # => false
  #   [1,2,3].map(&:to_i)
  #     # => [1,2,3]
  #
  def self.temporarily_monkeypatch(instance, method_name, &block)

    Thread.exclusive do
      @monkey_patch_count = @monkey_patch_count ? @monkey_patch_count + 1 : 0
      stashed_method_name = :"#{method_name}_without_metavariable_#{@monkey_patch_count}"
      thread = Thread.current

      # Try to get a handle on the object's singleton class, but fall back to using
      # its actual class where that is not possible (i.e. for numbers and symbols)
      klass = (class << instance; self; end) rescue instance.class
      klass.class_eval do

        alias_method(stashed_method_name, method_name) rescue nil
        define_method(method_name) do

          todo = block

          Thread.exclusive do
            if self.equal?(instance) && thread.equal?(Thread.current)

              klass.class_eval do
                undef_method(method_name)
                alias_method(method_name, stashed_method_name) rescue nil
                undef_method(stashed_method_name) rescue nil
              end

            else
              todo = method(stashed_method_name)
            end
          end

          todo.call
        end
      end
    end
  end
end

X = Metavariable.new
