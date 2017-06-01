require "rubygems"
require "bundler/setup"
require "riot"
require "treetop"
require_relative "Regex"

base_path = File.expand_path(File.dirname(__FILE__))
Treetop.load(File.join(base_path, 'Regex.treetop'))
parser = PatternParser.new

if __FILE__ == $0
  # puts "#{parser.parse("(a(|b))").inspect}"
  context "Regex Parser" do
    asserts "can recognise an empty string is an empty pattern" do
      parser.parse("").to_ast == Regex::Empty.new
    end

    asserts "can recognise a literal character" do
      parser.parse("a").to_ast == Regex::Literal.new("a")
    end

    asserts "can recognise a concatenation of two characters" do
      parser.parse("ab").to_ast == Regex::Concatenate.new(
        Regex::Literal.new("a"), Regex::Literal.new("b")
      )
    end

    asserts "can recognise a concatenation of three characters" do
      parser.parse("abc").to_ast == Regex::Concatenate.new(
        Regex::Literal.new("a"),
        Regex::Concatenate.new(
          Regex::Literal.new("b"),
          Regex::Literal.new("c")))
    end

    asserts "can recognise a complex expression" do
      expected = Regex::Repeat.new(
        Regex::Concatenate.new(
          Regex::Literal.new("a"),
          Regex::Option.new(
            Regex::Empty.new,
            Regex::Literal.new("b"))))
      result = parser.parse("(a(|b))*").to_ast
      result == expected
    end

    asserts "'(a(|b))*' matches 'aaabab'" do
      parser.parse("(a(|b))*").to_ast.matches?("aaabab")
    end

    asserts "'(a(|b))*' will not matches 'aaabbb'" do
      not parser.parse("(a(|b))*").to_ast.matches?("aaabbb")
    end
  end
end
