require "rubygems"
require "bundler/setup"
require "riot"
require "treetop"
require_relative "./base.rb"



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
end
