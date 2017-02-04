require "rubygems"
require "bundler/setup"
require "riot"
require "execjs"
require_relative "./base.rb"

=begin
Why do I use Javascript instead of ruby for the target
langauge in this sections?

I thought that it would be more interesting and clearer to see
denotational semantics across languages. Since I know JS and
running JS from Ruby is trivial (thanks to the ExecJS gem), it
makes the idea of cross-language semantic definition more obvious.

Also, the syntax ends up being almost identical anyway ;)
=end


#
# Utility function so that the result of our evaluations play nice
# with Ruby symbols. Note that this can't be trivially baked into
# the eval function since we have to deal with expressions, like
# numbers and booleans, that do not evaluate to an environment.
#
def symbolify(hash)
  Hash[hash.map{ |k, v| [k.to_sym, v] }]
end

def eval(prog, env="{}")
  ExecJS.eval "(#{prog.to_js})(#{env})"
end

class Number
  def to_js
    "e => (#{value})"
  end
end

context "Number" do
  asserts("will evaluate to their value"){
    9 == eval(Number.new(9))
  }
end

class Boolean
  def to_js
    "e => (#{value})"
  end
end


context "Boolean" do
  asserts("True is true"){
    true == eval(T)
  }
  asserts("False is false"){
    false == eval(F)
  }
end

class Assign
  def to_js
    "e => Object.assign(e, {#{name}: (#{expression.to_js})(e) }) "
  end
end

context "Assign" do
  asserts("can create a new variable"){
    program = Assign.new(:x, Number.new(9))
    result = symbolify(eval(program))
    result == {x:9}
  }

  asserts("can change existing variables"){
    program = Assign.new(:x, Number.new(9))
    result = symbolify(eval(program, "{x:0, y:0}"))
    result == {x:9, y:0}
  }
end

class Variable
  def to_js
    "e => e[\"#{name}\"]"
  end
end

context "Variable" do
  asserts("will be the assigned value"){
    program = Variable.new(:x)
    0 == eval(program, "{x:0}")
  }
end

class Add
  def to_js
    "e => ( (#{left.to_js})(e) + (#{right.to_js})(e) )"
  end
end

context "Add" do
  program = Add.new(Number.new(9), Number.new(9))
  asserts("#{program}"){eval(program)}.equals(18)
end

class Multiply
  def to_js
    "e => ( (#{left.to_js})(e) * (#{right.to_js})(e) )"
  end
end

context "Multiply" do
  program = Multiply.new(Number.new(9), Number.new(9))
  asserts("#{program}"){eval(program)}.equals(81)
end

class LessThan
  def to_js
    "e => ( (#{left.to_js})(e) < (#{right.to_js})(e) )"
  end
end

context "LessThan" do
  program1 = LessThan.new(Number.new(1), Number.new(9))
  asserts("#{program1}"){eval(program1)}.equals(true)
  program2 = LessThan.new(Number.new(9), Number.new(1))
  asserts("#{program2}"){eval(program2)}.equals(false)
end

class Noop
  def to_js
    "e => ( e )"
  end
end

context "Noop" do
  asserts("does nothing to an empty environment"){
    {} == eval(Noop.new, "{}")
  }
  asserts("does not change a populated environment"){
    program = Noop.new
    result = symbolify(eval(program, "{x:1, y:2}"))
    result == {x:1,y:2}
  }
end

class If
  def to_js
    "e => ( ((#{condition.to_js})(e))?((#{consequence.to_js})(e)):((#{alternative.to_js})(e)) )"
  end
end

context "If" do
  asserts("will evaluate the consequence if the condition is true"){
    program = If.new(T,
      Assign.new(:x, T),
      Assign.new(:y, T))


    final_env = symbolify(eval(program, "{}"))

    final_env == {x: true}
  }

  asserts("will evaluate the alternative if the condition is false"){
    program = If.new(F,
      Assign.new(:x, T),
      Assign.new(:y, T))

    final_env = symbolify(eval(program, "{}"))

    final_env == {y: true}
  }
end


class Sequence
  def to_js
    wrapped = @statements.inject("e") {|prev,s|
      "(#{s.to_js})(#{prev})"
    }
    "e => #{wrapped}"
  end
end

context "A Sequence" do
  asserts("will not change an empty environment when empty"){
    symbolify(eval(Sequence.new())) == {}
  }

  asserts("will evaluate a single statement"){
    e = symbolify(eval(Sequence.new(Assign.new(:x, T))))
    e == {x: true}
  }

  asserts("will evaluate all statements in a sequence"){
    s1 = Assign.new(:x, Number.new(0))
    s2 = Assign.new(:x, Add.new(Variable.new(:x), Number.new(1)))
    s3 = Assign.new(:y, Number.new(9))
    s = Sequence.new(s1,s2,s3)
    result = symbolify(eval(s))
    result == {x: 1, y:9}
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

    result = symbolify(eval(program))

    result == {
      x: 1,
      y: 4,
      z: 4
    }
  }
end

class While
  def to_js
    "e=> {while( (#{condition.to_js})(e) ){
    Object.assign(e, (#{body.to_js})(e) );
    }; return e;}"
  end
end

context "A While loop" do
  asserts("with a false condition will skip the while body"){
    program = While.new(F, Assign.new(:x, T))
    symbolify(eval(program)) == {}
  }

  asserts("with a true condition will execute the while body"){
    program = While.new(Variable.new(:x), Assign.new(:x, F))
    symbolify(eval(program, "{x:true}")) == {x:false}
  }

  asserts("can be used to do something N times"){
    program = Sequence.new(
      Assign.new(:N, Number.new(0)),
      While.new(
        LessThan.new(Variable.new(:N), Number.new(10)),
        Assign.new(:N, Add.new(Variable.new(:N), Number.new(1)))))

    result = symbolify(eval(program))

    result == { N: 10 }
  }
end
