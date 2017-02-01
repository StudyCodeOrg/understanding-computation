require "rubygems"
require "bundler/setup"
require "riot"


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

  def reduce(env)
    if left.reducible?
      Add.new(left.reduce(env), right)
    elsif right.reducible?
      Add.new(left, right.reduce(env))
    else
      Number.new(left.value+right.value)
    end
  end
end

class Multiply < Struct.new(:left, :right)
  include Inspectable
  include Reducible

  def to_s
    "#{left} * #{right}"
  end

  def reduce(env)
    if left.reducible?
      Multiply.new(left.reduce(env), right)
    elsif right.reducible?
      Multiply.new(left, right.reduce(env))
    else
      Number.new(left.value*right.value)
    end
  end
end

context "SIMPLE expressions" do
    asserts("Add is reducible"){Add.new(nil,nil).reducible?}
    asserts("Number is irreducible"){not Number.new(nil).reducible?}
    asserts("Multiply is reducible"){Multiply.new(nil,nil).reducible?}

    asserts("Reducing Add.new(Number.new(9),Number.new(9))"){
      Add.new(Number.new(9),Number.new(9)).reduce(nil)
    }.equals(Number.new(18))

    asserts("Reducing Multiply.new(Number.new(9),Number.new(9)))"){
      Multiply.new(Number.new(9),Number.new(9)).reduce(nil)
    }.equals(Number.new(81))
end

class Machine <Struct.new(:expression)
  def step
    self.expression = expression.reduce(nil)
  end
  def run (display=false)
    while expression.reducible?
      if display
        puts expression
      end
      step
    end
    if display
      puts expression
    end
    expression
  end
end

expression = Add.new(
  Multiply.new(Number.new(9),Number.new(7)),
  Add.new(Number.new(3),Number.new(9))
)
machine = Machine.new(expression)
result = machine.run

context "SIMPLE simple steps Machine" do
  asserts("Running the machine on #{expression}"){result}.equals(Number.new(75))
end

class Boolean <Struct.new(:value)
  include Irreducible
  include Inspectable
  def to_s
    value.to_s
  end
end

class LessThan <Struct.new(:left, :right)
  include Reducible
  include Inspectable
  def to_s
    "#{left} < #{right}"
  end

  def reduce(env)
    if left.reducible?
      LessThan.new(left.reduce(env), right)
    elsif right.reducible?
      LessThan.new(left, right.reduce(env))
    else
      Boolean.new(left.value < right.value)
    end
  end
end

context "Booleans" do
  asserts("cannot be reduced"){not Boolean.new(false).reducible?}
end

context "LessThan" do
  asserts("is reducible"){LessThan.new(nil,nil).reducible?}

  asserts("will reduce down to true if appropriate"){
    LessThan.new(Number.new(1), Number.new(9)).reduce(nil)
  }.equals(Boolean.new(true))

  asserts("will reduce down to false if appropriate"){
    LessThan.new(Number.new(9), Number.new(1)).reduce(nil)
  }.equals(Boolean.new(false))
end

class Variable < Struct.new(:name)
  include Inspectable
  include Reducible
  def to_s
    name.to_s
  end
  def reduce(env)
    env[name]
  end
end

# We need a smarter machine

class VariableMachine < Struct.new(:expression, :environment)
  def step
    self.expression = expression.reduce(environment)
  end
  def run (display=false)
    while expression.reducible?
      if display
        puts expression
      end
      step
    end
    if display
      puts expression
    end
    expression
  end
end

context "A VariableMachine" do
  asserts("will reduce a variable to its value"){
    result = VariableMachine.new(
      Variable.new(:x),
      {x: Number.new(9)}
    ).run
    result == Number.new(9)
  }

  asserts("will reduce more complex expressions"){
    expression = Add.new(
      Multiply.new(Variable.new(:a),Variable.new(:b)),
      Add.new(Variable.new(:c),Variable.new(:d))
    )
    environment = {
      a: Number.new(2),
      b: Number.new(3),
      c: Number.new(4),
      d: Number.new(5)
    }
    machine = VariableMachine.new(expression, environment)
    results = machine.run
    results == Number.new(15)
  }
end
