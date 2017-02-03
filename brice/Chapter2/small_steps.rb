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

context "Expressions" do
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

context "Simple Machine" do
  asserts("Running the machine on #{expression}"){result}.equals(Number.new(75))
end

class Boolean <Struct.new(:value)
  include Irreducible
  include Inspectable
  def to_s
    value.to_s
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
  asserts("cannot be reduced"){not F.reducible?}
end

context "LessThan" do
  asserts("is reducible"){LessThan.new(nil,nil).reducible?}

  asserts("LessThan.new(Number.new(1), Number.new(9))"){
    LessThan.new(Number.new(1), Number.new(9)).reduce(nil)
  }.equals(T)

  asserts("LessThan.new(Number.new(9), Number.new(1))"){
    LessThan.new(Number.new(9), Number.new(1)).reduce(nil)
  }.equals(F)
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

  def reduce(environment)
    if expression.reducible?
      [Assign.new(name, expression.reduce(environment)), environment]
    else
      [Noop.new, environment.merge({name=>expression})]
    end
  end
end

class StatementMachine < Struct.new(:statement, :environment)
  def step
    self.statement, self.environment = statement.reduce(environment)
  end
  def show
    puts "#{statement}, #{environment}"
  end
  def run (display=false)
    while statement.reducible?
      if display; show end
      step
    end
    if display; show end
    [statement, environment]
  end
end

context "A StatementMachine" do
  asserts("will ignore a noop"){
    statement = Noop.new
    start_environment = {x: Number.new(9)}
    result_statement, result_env = StatementMachine.new(statement, start_environment).run
    (result_statement == Noop.new) && (result_env == start_environment)
  }
end

context "An Assigment" do
  asserts("will change the environment and reduce to a noop"){
    statement = Assign.new(:x, Number.new(9))
    start_environment = {}
    result_statement, result_env = StatementMachine.new(statement, start_environment).run
    (result_statement == Noop.new) && (result_env == {x: Number.new(9)})
  }
end


class If < Struct.new(:condition, :consequence, :alternative)
  include Reducible
  include Inspectable
  def to_s
    "if (#{condition}){ #{consequence} } else { #{alternative} }"
  end
  def reduce(env)
    if condition.reducible?
      [If.new(condition.reduce(env), consequence, alternative), env]
    else
      case condition
      when T
        [consequence,env]
      when F
        [alternative,env]
      end
    end
  end
end

class KIrreducible
  include Irreducible
end


context "An If statement" do
  asserts("will reduce to the consequence if the the condition is true"){
    consequence = Object.new
    alternative = Object.new
    statement, _ = If.new(T, consequence, alternative).reduce(nil)
    statement.equal?(consequence)
  }

  asserts("will reduce to the alternative if the the condition is false"){
    consequence = Object.new
    alternative = Object.new
    statement, _ = If.new(F, consequence, alternative).reduce(nil)
    statement.equal?(alternative)
  }

  asserts("will reduce the condition if needed"){
    condition = LessThan.new(Number.new(1), Number.new(3))
    consequence = KIrreducible.new
    alternative = KIrreducible.new
    if_statement = If.new(condition, consequence, alternative)
    while if_statement.reducible?
      if_statement, _ = if_statement.reduce(nil)
    end

    if_statement.equal?(consequence)
  }

  asserts("plays well with the StatementMachine"){
    condition = LessThan.new(Number.new(1), Number.new(3))
    consequence = Assign.new(:x, T)
    alternative = Assign.new(:x, F)
    statement = If.new(condition, consequence, alternative)
    start_env = {}
    machine = StatementMachine.new(statement, start_env)

    final_statement, final_env = machine.run

    (final_env == {x: T}) && (final_statement == Noop.new)
  }
end

class Sequence
  include Reducible
  include Inspectable
  def initialize(*statements)
    @statements = statements
  end
  def to_s
    @statements.join "; "
  end
  def reduce(env)
    head = @statements.first
    return [Noop.new, env] if head.nil?

    tail = @statements.drop(1)
    if head.reducible?
      s, new_env = head.reduce(env)
      [Sequence.new(*[s].concat(tail)), new_env]
    elsif tail.size > 0
        [Sequence.new(*tail), env]
    else
      [head, env]
    end
  end
end

context "A Sequence" do
  asserts("will return a noop when empty"){
    s,e = Sequence.new().reduce({})
    (s==Noop.new) && (e == {})
  }

  asserts("will return a single irreducible statement as is"){
    statement = KIrreducible.new
    s,e = Sequence.new(statement).reduce({})
    s == statement
  }

  asserts("will return the last irreducible statement in a sequence"){
    s1 = KIrreducible.new
    s2 = KIrreducible.new
    s3 = KIrreducible.new
    s = Sequence.new(s1,s2,s3)

    while s.instance_of?(Sequence)
      s,e = s.reduce({})
    end

    s == s3
  }

  asserts("plays well with the StatementMachine"){
    statement = Sequence.new(
      Assign.new(:x, Number.new(1)),
      Assign.new(:y, Number.new(4)),
      If.new(
        LessThan.new(Variable.new(:y), Variable.new(:x)),
        Assign.new(:z, Add.new(Variable.new(:y), Variable.new(:x))),
        Assign.new(:z, Multiply.new(Variable.new(:y), Variable.new(:x))),
      )
    )
    machine = StatementMachine.new(statement, {})
    final_statement, final_environment = machine.run
    final_environment
  }.equals({
    x: Number.new(1),
    y: Number.new(4),
    z: Number.new(4)
  })
end

class While < Struct.new(:condition, :body)
  include Reducible
  include Inspectable
  def to_s
    "while ( #{condition} ) { #{body} }"
  end

  def reduce(env)
    [If.new(condition, Sequence.new(body,self), Noop.new), env]
  end
end

context "A While loop" do
  asserts("with a false condition will skip the while body"){
    program = While.new(F, Assign.new(:x, T))
    machine = StatementMachine.new(program, {})

    final_statement, final_env = machine.run

    final_env == {}
  }

  asserts("with a true condition will execute the while body"){
    program = While.new(Variable.new(:x), Assign.new(:x, F))
    machine = StatementMachine.new(program, {x: T})

    final_statement, final_env = machine.run

    final_env == {x: F}
  }

  asserts("can be used to do something N times"){
    program = Sequence.new(
      Assign.new(:N, Number.new(0)),
      While.new(
        LessThan.new(Variable.new(:N), Number.new(10)),
        Assign.new(:N, Add.new(Variable.new(:N), Number.new(1)))))
    start_env = {}
    machine = StatementMachine.new(program, start_env)

    final_statement, final_environment = machine.run()

    final_environment == { N: Number.new(10) }
  }
end
