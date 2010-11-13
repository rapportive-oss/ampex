require 'blankslate'

# Copyright 2010 Conrad Irwin <conrad.irwin@gmail.com> MIT License
#
# For detailed usage notes, please see README.markdown
#
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
