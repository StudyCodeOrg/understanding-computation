
module Inspectable
  def inspect
    "«#{self}»"
  end
end

module Reducible
  def reducible?
    true
  end
end

module Irreducible
  def reducible?
    false
  end
end


class Number < Struct.new(:value)
  include Inspectable
  include Irreducible
  def to_s
    value.to_s
  end
end


class Add < Struct.new(:left, :right)
  include Inspectable
  include Reducible
  def to_s
    "#{left} + #{right}"
  end
end

class Multiply < Struct.new(:left, :right)
  include Inspectable
  include Reducible
  def to_s
    "#{left} * #{right}"
  end
end

class Boolean <Struct.new(:value)
  include Irreducible
  include Inspectable
  def to_s
    value.to_s
  end
  def ==(other)
    value == other.value
  end
end


T = Boolean.new(true)
F = Boolean.new(false)

class LessThan <Struct.new(:left, :right)
  include Reducible
  include Inspectable
  def to_s
    "#{left} < #{right}"
  end
end


class Variable < Struct.new(:name)
  include Inspectable
  include Reducible
  def to_s
    name.to_s
  end
end

class Noop
  include Irreducible
  include Inspectable
  def to_s
    "Noop"
  end
  def ==(other)
    other.instance_of?(Noop)
  end
end


class Assign < Struct.new(:name, :expression)
  include Reducible
  include Inspectable
  def to_s
    "#{name} = #{expression}"
  end
end

class If < Struct.new(:condition, :consequence, :alternative)
  include Reducible
  include Inspectable
  def to_s
    "if (#{condition}){ #{consequence} } else { #{alternative} }"
  end
end

class Sequence
  include Reducible
  include Inspectable
  attr_reader :statements
  def initialize(*statements)
    @statements = statements
  end
  def to_s
    "[" + @statements.join("; ") + "]"
  end
  def ==(other)
    @statements.zip(other.statements).map{|a,b| a == b}.all?
  end
end

class While < Struct.new(:condition, :body)
  include Reducible
  include Inspectable
  def to_s
    "while ( #{condition} ) { #{body} }"
  end
end
