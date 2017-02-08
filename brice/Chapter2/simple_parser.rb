require "rubygems"
require "bundler/setup"
require "riot"
require "treetop"
require_relative "./base.rb"
require_relative "./big-step.rb"



base_path = File.expand_path(File.dirname(__FILE__))
Treetop.load(File.join(base_path, 'simple.treetop'))
parser = SimpleParser.new


context "The Simple Parser" do
  asserts("False is false"){
    Boolean.new(false) == F
  }

  asserts("can recognise a variable"){
    program = "x"
    expect_AST = Variable.new(:x)
    actual_AST = parser.parse(program).to_ast
    actual_AST == expect_AST
  }

  asserts("thinks '13'"){
    # puts parser.parse("13").inspect
    # puts parser.parse("13").elements.inspect
    parser.parse("13").to_ast
  }.equals(Number.new(13))

  asserts("thinks '3.14'"){
    parser.parse("3.14").to_ast
  }.equals(Number.new(3.14))

  asserts("thinks 'x = 1'"){
    parser.parse("x = 1").to_ast
  }.equals(Assign.new(:x, Number.new(1)))

  asserts("thinks 'x=1'"){
    parser.parse("x=1").to_ast
  }.equals(Assign.new(:x, Number.new(1)))

  asserts("can parse multiple statements"){
    program = "x=1; y=2"
    parser.parse(program).to_ast
  }.equals(Sequence.new(
    Assign.new(:x, Number.new(1)),
    Assign.new(:y, Number.new(2))
  ))

  asserts("can parse multiplications"){
    program = "3 * 3"
    parser.parse(program).to_ast
  }.equals(Multiply.new(Number.new(3), Number.new(3)))

  asserts("can parse decimal multiplications"){
    program = "3.0 * 3.0"
    parser.parse(program).to_ast
  }.equals(Multiply.new(Number.new(3.0), Number.new(3.0)))

  asserts("can parse addition"){
    program = "3 + 3"
    parser.parse(program).to_ast
  }.equals(Add.new(Number.new(3), Number.new(3)))

  asserts("can parse decimal addition"){
    program = "3.0 + 3.0"
    parser.parse(program).to_ast
  }.equals(Add.new(Number.new(3.0), Number.new(3.0)))

  asserts("can parse less than"){
    program = "1 < 3"
    parser.parse(program).to_ast
  }.equals(LessThan.new(Number.new(1), Number.new(3)))

  asserts("can parse true"){
    # puts parser.parse("true").inspect
    parser.parse("true").to_ast
  }.equals(T)

  asserts("can parse false"){
    parser.parse("false").to_ast
  }.equals(F)

  asserts("can parse while statement with single body statement"){
    program = "while (true){ x = 1; }"
    expected = While.new(T,
        Assign.new(:x, Number.new(1))
      )
    result = parser.parse(program).to_ast
    result == expected
  }

  asserts("can parse while statement with multiple body statement"){
    program = "while (true){
      x = 1;
      y = 2.0;
    }"
    expected = While.new(T,
      Sequence.new(
        Assign.new(:x, Number.new(1)),
        Assign.new(:y, Number.new(2.0))
      ))
    result = parser.parse(program).to_ast
    result == expected
  }

  asserts("can parse if statement with single statement, no alternative"){
    program = "if (true){
      x = 1
    }"
    expected = If.new(T,
        Assign.new(:x, Number.new(1)), Noop.new
      )
    result = parser.parse(program).to_ast
    result == expected
  }

  asserts("can parse if statement with single consequence, single alternative"){
    program = "if (true){
      x = 1
    } else {
      y = 2
    }"
    expected = If.new(T,
        Assign.new(:x, Number.new(1)),
        Assign.new(:y, Number.new(2)),
      )
    result = parser.parse(program).to_ast
    result == expected
  }

  asserts("can parse if statement with multiple consequences, multiple alternatives"){
    program = "if (true){
      x = 1;
      k = 9;
    } else {
      y = 2;
      i = 89;
    }"
    expected = If.new(T,
      Sequence.new(
        Assign.new(:x, Number.new(1)),
        Assign.new(:k, Number.new(9))),
      Sequence.new(
        Assign.new(:y, Number.new(2)),
        Assign.new(:i, Number.new(89)))
      )
    result = parser.parse(program).to_ast
    result == expected
  }


  asserts("can parse multiple statements"){
    program = "
    x = 1;
    y = 4;
    "
    expected = Sequence.new(
      Assign.new(:x, Number.new(1)),
      Assign.new(:y, Number.new(4))
    )
    result = parser.parse(program).to_ast
    result == expected
  }
  asserts("can parse a complete program"){
    program = "
    x = 1;
    y = 4;
    if ( y < x ) {
      z = y + x;
    } else {
      z = y * x;
    };
    "
    expected = Sequence.new(
      Assign.new(:x, Number.new(1)),
      Assign.new(:y, Number.new(4)),
      If.new(
        LessThan.new(Variable.new(:y), Variable.new(:x)),
        Assign.new(:z, Add.new(Variable.new(:y), Variable.new(:x))),
        Assign.new(:z, Multiply.new(Variable.new(:y), Variable.new(:x))),
      )
    )

    result = parser.parse(program).to_ast
    result == expected
  }

  asserts("can parse the book's test program"){
    program = "while (x < 5) { x = x * 3 }"
    abstract_syntax_tree = parser.parse(program).to_ast
    env = abstract_syntax_tree.evaluate({x: Number.new(1)})
    env == {x: Number.new(9)}
  }
end
