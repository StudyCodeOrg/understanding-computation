require "rubygems"
require "bundler/setup"
require "riot"
require_relative "./base.rb"

class Number
  def evaluate(env)
    self
  end
end

context "A Number" do
  asserts("evaluates to itself"){
    Number.new(1).evaluate({}) == Number.new(1)
  }

  asserts("is different to another number"){
    Number.new(1).evaluate({}) != Number.new(2)
  }
end

class Boolean
  def evaluate(env)
    self
  end
end

context "A Boolean" do
  asserts("evaluates to itself"){
    T.evaluate({}) == T
  }
  asserts("is different from its inverse"){
    T.evaluate({}) != F
  }
end

class Variable
  def evaluate(env)
    env[name]
  end
end

context "A Variable" do
  asserts("evaluates to its value in the environment"){
    value = Number.new(0)
    Variable.new(:x).evaluate({x: value}) == value
  }
end

class Add
  def evaluate(env)
    Number.new(left.evaluate(env).value + right.evaluate(env).value)
  end
end

context "Add" do
  asserts("will add two numbers"){
    program = Add.new(Number.new(9), Number.new(9))

    answer = program.evaluate({})

    answer == Number.new(18)
  }
end

class Multiply
  def evaluate(env)
    Number.new(left.evaluate(env).value * right.evaluate(env).value)
  end
end


context "Multiply" do
  asserts("will multiply two numbers"){
    program = Multiply.new(Number.new(9), Number.new(9))

    answer = program.evaluate({})

    answer == Number.new(81)
  }
end

class LessThan
  def evaluate(env)
    if left.evaluate(env).value < right.evaluate(env).value
      T
    else
      F
    end
  end
end

context "LessThan" do
  asserts("will evaluate to false when appropriate"){
    program = LessThan.new(Number.new(9), Number.new(0))

    result = program.evaluate({})

    result == F
  }

  asserts("will evaluate to true when appropriate"){
    program = LessThan.new(Number.new(0), Number.new(9))

    result = program.evaluate({})

    result == T
  }
end

class Noop
  def evaluate(env)
    env
  end
end

context "Noop" do
  asserts("will not change an empty environment"){
    Noop.new.evaluate({}) == {}
  }

  asserts("will not change an populated environment"){
    Noop.new.evaluate({x: 123}) == {x: 123}
  }
end

class Assign
  def evaluate(env)
    env.merge({ name => expression.evaluate(env) })
  end
end

context "Assign" do
  asserts("will set the value of a new variable"){
    program = Assign.new(:x, Number.new(9))

    final_env = program.evaluate({})

    final_env == {x: Number.new(9)}
  }

  asserts("will change the value of an existing variable"){
    program = Assign.new(:x, Number.new(9))

    final_env = program.evaluate({x: Number.new(1)})

    final_env == {x: Number.new(9)}
  }
end

class If
  def evaluate(env)
    case condition.evaluate(env)
    when T
      consequence.evaluate(env)
    when F
      alternative.evaluate(env)
    end
  end
end

context "If" do
  asserts("Will evaluate the consequence if the condition is true"){
    program = If.new(T,
      Assign.new(:x, T),
      Assign.new(:y, T))

    final_env = program.evaluate({})

    final_env == {x: T}
  }

  asserts("Will evaluate the alternative if the condition is false"){
    program = If.new(F,
      Assign.new(:x, T),
      Assign.new(:y, T))

    final_env = program.evaluate({})

    final_env == {y: T}
  }
end

class Sequence
  def evaluate(env)
    @statements.inject(env){|env,exp| exp.evaluate(env)}
  end
end

context "A Sequence" do
  asserts("will not change an empty environment when empty"){
    Sequence.new().evaluate({}) == {}
  }

  asserts("will evaluate a single statement"){
    e = Sequence.new(Assign.new(:x, T)).evaluate({})
    e == {x: T}
  }

  asserts("will evaluate all statements in a sequence"){
    s1 = Assign.new(:x, Number.new(0))
    s2 = Assign.new(:x, Add.new(Variable.new(:x), Number.new(1)))
    s3 = Assign.new(:y, Number.new(9))
    s = Sequence.new(s1,s2,s3)

    s.evaluate({}) == {x: Number.new(1), y: Number.new(9)}
  }

  asserts("will evaluate complex programs"){
    program = Sequence.new(
      Assign.new(:x, Number.new(1)),
      Assign.new(:y, Number.new(4)),
      If.new(
        LessThan.new(Variable.new(:y), Variable.new(:x)),
        Assign.new(:z, Add.new(Variable.new(:y), Variable.new(:x))),
        Assign.new(:z, Multiply.new(Variable.new(:y), Variable.new(:x))),
      )
    )

    final_environment = program.evaluate({})

    final_environment == {
      x: Number.new(1),
      y: Number.new(4),
      z: Number.new(4)
    }
  }
end

class While
  def evaluate(env)
    case condition.evaluate(env)
    when T
      evaluate(body.evaluate(env))
    when F
      env
    end
  end
end

context "A While loop" do
  asserts("with a false condition will skip the while body"){
    program = While.new(F, Assign.new(:x, T))

    program.evaluate({}) == {}
  }

  asserts("with a true condition will execute the while body"){
    program = While.new(Variable.new(:x), Assign.new(:x, F))

    program.evaluate({x:T}) == {x: F}
  }

  asserts("can be used to do something N times"){
    program = Sequence.new(
      Assign.new(:N, Number.new(0)),
      While.new(
        LessThan.new(Variable.new(:N), Number.new(10)),
        Assign.new(:N, Add.new(Variable.new(:N), Number.new(1)))))

    program.evaluate({}) == { N: Number.new(10) }
  }
end
