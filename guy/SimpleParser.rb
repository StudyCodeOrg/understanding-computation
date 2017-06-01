#SimpleParser
require "rubygems"
require "bundler/setup"
require "riot"
require "treetop"
require_relative "../brice/chapter2/base.rb"
require_relative "../brice/chapter2/big-step.rb"




base_path = File.expand_path(File.dirname(__FILE__))
Treetop.load(File.join(base_path, 'simple.treetop'))
parser = SimpleParser.new


context "Simple grammar" do
  asserts "'11' is parsed as a number" do
    program = "11"
    expect_AST = Number.new(11)
    actual_AST = parser.parse(program).to_ast
    actual_AST == expect_AST
  end
  asserts "1.2 is parsed as a decimal" do
    program = "1.2"
    expect_AST = Number.new(1.2)
    actual_AST = parser.parse(program).to_ast
    actual_AST == expect_AST
  end
  asserts "-1 is parsed as a number" do
    program = "-1"
    expect_AST = Number.new(-1)
    actual_AST = parser.parse(program).to_ast
    actual_AST == expect_AST
  end
  asserts "-1.2 is parsed as a number" do
    program = "-1.2"
    expect_AST = Number.new(-1.2)
    actual_AST = parser.parse(program).to_ast
    actual_AST == expect_AST
  end
  asserts "-0 is parsed as a number" do
    program = "-0"
    expect_AST = Number.new(-0)
    actual_AST = parser.parse(program).to_ast
    actual_AST == expect_AST
  end
  asserts "x is parsed as a variable" do
    program = "x"
    expect_AST = Variable.new(:x)
    actual_AST = parser.parse(program).to_ast
    actual_AST == expect_AST
  end
  asserts "xo is parsed as a variable" do
    program = "xo"
    expect_AST = Variable.new(:xo)
    actual_AST = parser.parse(program).to_ast
    actual_AST == expect_AST
  end
  asserts "False is parsed as a boolean" do
    program = "False"
    expect_AST = Boolean.new(false)
    actual_AST = parser.parse(program).to_ast
    actual_AST == expect_AST
  end
  asserts "True is parsed as a boolean" do
    program = "True"
    expect_AST = Boolean.new(true)
    actual_AST = parser.parse(program).to_ast
    actual_AST == expect_AST
  end

  context "Math" do
    asserts "'1 + 1' is parsed as an addition" do
      program = "1 + 1"
      expect_AST = Add.new(Number.new(1), Number.new(1))
      actual_AST = parser.parse(program).to_ast
      actual_AST == expect_AST
    end

    asserts "'x + 1' is parsed as an addition" do
      program = "x + 1"
      expect_AST = Add.new(Variable.new(:x), Number.new(1))
      actual_AST = parser.parse(program).to_ast
      actual_AST == expect_AST
    end

    asserts "'4 * 4' is parsed as multiplication" do
      program = "4 * 4"
      expect_AST = Multiply.new(Number.new(4), Number.new(4))
      actual_AST = parser.parse(program).to_ast
      actual_AST == expect_AST
    end

    asserts "'x * 4' is parsed as multiplication" do
      program = "x * 4"
      expect_AST = Multiply.new(Variable.new(:x), Number.new(4))
      actual_AST = parser.parse(program).to_ast
      actual_AST == expect_AST
    end

    asserts "'x < 4' is parsed as a comparison" do
      program = "x < 4"
      expect_AST = LessThan.new(Variable.new(:x), Number.new(4))
      actual_AST = parser.parse(program).to_ast
      actual_AST == expect_AST
    end

    asserts "'1 + 2 * 3' should be parsed as a 1+(2*3)" do
      program = "1 + 2 * 3"
      expect_AST = Add.new(Number.new(1), Multiply.new(Number.new(2), Number.new(3)))
      actual_AST = parser.parse(program).to_ast
      actual_AST == expect_AST
    end

    # asserts "'1 * 2 + 3' should be parsed as a (1*2)+3" do
    #   program = "1 * 2 + 3"
    #   expect_AST = Add.new(Multiply.new(Number.new(1), Number.new(2)), Number.new(3))
    #   actual_AST = parser.parse(program).to_ast
    #   puts "#{actual_AST.inspect}"
    #   actual_AST == expect_AST
    # end
  end

  context "Statement" do
    asserts "'x = 1' is parsed as an assignment expression" do
      program = "x = 1"
      expect_AST = Assign.new(:x, Number.new(1))
      actual_AST = parser.parse(program).to_ast
      actual_AST == expect_AST
    end

    asserts "'x = y + 3' is parsed as an assignment expression" do
      program = "x = y + 3"
      expect_AST = Assign.new(:x, Add.new(Variable.new(:y), Number.new(3)))
      actual_AST = parser.parse(program).to_ast
      actual_AST == expect_AST
    end

    asserts "'1+1; 2+2' should parse as a sequence" do
      program = "1+1; 2+2"
      expect_AST = Sequence.new(
        Add.new(Number.new(1), Number.new(1)),
        Add.new(Number.new(2), Number.new(2)),
      )
      actual_AST = parser.parse(program).to_ast
      actual_AST == expect_AST
    end

    asserts "'1+1; 2+2;' should parse as a sequence" do
      program = "1+1; 2+2;"
      expect_AST = Sequence.new(
        Add.new(Number.new(1), Number.new(1)),
        Add.new(Number.new(2), Number.new(2)),
      )
      actual_AST = parser.parse(program).to_ast
      actual_AST == expect_AST
    end

    asserts "'1+1;' should parse as an addition" do
      program = "1+1;"
      expect_AST = Add.new(Number.new(1), Number.new(1))
      actual_AST = parser.parse(program).to_ast
      actual_AST == expect_AST
    end

    asserts "';;' should not parse as a valid program" do
      program = ";;"
      expect_AST = nil
      actual_AST = parser.parse(program)
      actual_AST == expect_AST
    end

    asserts "'if( True ) { 1+1 }' will be parsed as a simple conditional statement" do
      program = "if( True ) { 1+1 }"
      expect_AST = If.new(
        Boolean.new(true),
        Add.new(Number.new(1), Number.new(1)),
        Noop.new)
      actual_AST = parser.parse(program).to_ast
      actual_AST == expect_AST
    end

    asserts "'if( 1 < 2 ) { 1+1 }' will be parsed as a simple conditional statement" do
      program = "if( 1 < 2 ) { 1+1 }"
      expect_AST = If.new(
        LessThan.new(Number.new(1), Number.new(2)),
        Add.new(Number.new(1), Number.new(1)),
        Noop.new)
      actual_AST = parser.parse(program).to_ast
      actual_AST == expect_AST
    end

    asserts "'if( 1 < 2 ) { 1+1 } else { 3 + 3 }' will be parsed as a simple conditional statement" do
      program = "if( 1 < 2 ) { 1+1 } else { 3 + 3 }"
      expect_AST = If.new(
        LessThan.new(Number.new(1), Number.new(2)),
        Add.new(Number.new(1), Number.new(1)),
        Add.new(Number.new(3), Number.new(3)))
      actual_AST = parser.parse(program).to_ast
      actual_AST == expect_AST
    end

    asserts "'while( True ) { 1 + 1 }' will be parsed as a simple while loop" do
      program = "while( True ) { 1 + 1 }"
      expect_AST = While.new(
        Boolean.new(true),
        Add.new(Number.new(1), Number.new(1)))
      actual_AST = parser.parse(program).to_ast
      actual_AST == expect_AST
    end

    asserts "'while( ) { 1 + 1 }' will fail to parse" do
      program = "while( ) { 1 + 1 }"
      nil == parser.parse(program)
    end

    asserts "'while( x < 1 ) { y = 3 + z; x = y + 3  }' will be parsed will a sequence as the body of the while loop" do
      program = "while( x < 1 ) { y = 3 + z; x = y + 3  }"
      expect_AST = While.new(
        LessThan.new(Variable.new(:x), Number.new(1)),
        Sequence.new(
          Assign.new(:y, Add.new(Number.new(3), Variable.new(:z))),
          Assign.new(:x, Add.new(Variable.new(:y), Number.new(3)))))
      actual_AST = parser.parse(program).to_ast
      actual_AST == expect_AST
    end

    asserts "'while( True ) {  }' will be parsed as a while loop with a Noop" do
      program = "while( True ) { }"
      expect_AST = While.new(Boolean.new(true), Noop.new())
      actual_AST = parser.parse(program).to_ast
      actual_AST == expect_AST
    end

    asserts "'x = 0; while(x < 10){ x = x +1 }' will parse as a compound program made up of a sequence" do
      program = "x = 0; while(x < 10){ x = x +1 }"
      expect_AST = Sequence.new(
        Assign.new(:x, Number.new(0)),
        While.new(
          LessThan.new(Variable.new(:x), Number.new(10)),
          Assign.new(:x, Add.new(Variable.new(:x), Number.new(1)))))
      actual_AST = parser.parse(program).to_ast
      actual_AST == expect_AST
    end
  end

end
