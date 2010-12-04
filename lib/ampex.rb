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
    Metavariable.temporarily_monkeypatch(args.last.class, mv) if name.to_s =~ /[^!=<>]=$/
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
  # There is a risk if someone uses an amp-less X, and assigns something with to_proc
  # (most likely a symbol), and then uses .map(&:to_i), as &:to_i will return the
  # behaviour of their metavariable.
  #
  # There are other things that might notice us doing this, if people are listening
  # on various method_added hooks, or have overridden class_eval, etc. But I'm not
  # too worried.
  #
  def self.temporarily_monkeypatch(klass, mv)
    klass.send :class_variable_set, :'@@metavariable', mv
    klass.class_eval do

      alias_method(:to_proc_without_metavariable, :to_proc) rescue nil
      def to_proc
        self.class.class_eval do

          undef to_proc
          alias_method(:to_proc, :to_proc_without_metavariable) rescue nil
          undef to_proc_without_metavariable rescue nil

          # Remove the metavariable from the class and return its proc
          remove_class_variable(:'@@metavariable').to_proc
        end
      end
    end
  end
end

X = Metavariable.new
