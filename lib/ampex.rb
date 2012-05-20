# Copyright 2010 Conrad Irwin <conrad.irwin@gmail.com> MIT License
#
# For detailed usage notes, please see README.markdown

# NOTE: Ruby 1.9 seems to provide a default blank slate that isn't
# very blank, luckily it also provides a BasicObject which is pretty
# basic.
if defined? BasicObject
  superclass = BasicObject
else
  require 'rubygems'
  require 'blankslate'
  superclass = BlankSlate
end

class Metavariable < superclass
  # When you pass an argument with & in ruby, you're actually calling #to_proc
  # on the object. So it's Symbol#to_proc that makes the &:to_s trick work,
  # and Metavariable#to_proc that makes &X work.
  attr_reader :to_proc

  def initialize(&block)
    @to_proc = block || ::Proc.new{|x| x}
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
    raise ::NotImplementedError, "(&X = 'foo') is unsupported in ampex > 2.0.0" if name.to_s =~ /[^!=<>]=$/
    ::Metavariable.new { |x| @to_proc.call(x).__send__(name, *args, &block) }
  end

  # BlankSlate and BasicObject have different sets of methods that you don't want.
  # let's remove them all.
  instance_methods.each do |method|
    undef_method method unless %w(method_missing to_proc __send__ __id__).include? method.to_s
  end
end

X = Metavariable.new
