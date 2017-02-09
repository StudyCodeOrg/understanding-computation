require "rubygems"
require "bundler/setup"
require "riot"
require_relative "FA"
require_relative "NFA"

module Regex
  module Pattern
    def bracket(outer_precedence)
      if precedence < outer_precedence
        "("+to_s+")"
      else
        to_s
      end
    end
    def inspect
      "/#{self}/"
    end
    def matches?(string)
      self.to_nfa_runner.accepts?(string)
    end
  end

  class Empty
    include Pattern
    def to_s
      ""
    end
    def precedence
      3
    end
    def to_nfa_runner
      start = Object.new
      accepts = [start]
      NFA::Runner.new(start, accepts, NFA::Rulebook.new([]))
    end
  end

  class Literal < Struct.new(:char)
    include Pattern
    def to_s
      char
    end
    def precedence
      3
    end
    def to_nfa_runner
      start = Object.new
      accept = Object.new
      NFA::Runner.new(start, [accept], NFA::Rulebook.new([
        FA::Rule.new(start, char, accept)
      ]))
    end
  end

  class Concatenate <Struct.new(:first, :second)
    include Pattern
    def to_s
      [first,second].map{|pattern| pattern.bracket(precedence)}.join
    end
    def precedence
      1
    end
    def to_nfa_runner
      first_nfa = first.to_nfa_runner
      second_nfa = second.to_nfa_runner
      new_rules = first_nfa.accept_states.map {|s| FA::Rule.new(s, nil, second_nfa.start_state)}
      rules = first_nfa.rulebook.rules + second_nfa.rulebook.rules + new_rules
      NFA::Runner.new(first_nfa.start_state, second_nfa.accept_states, NFA::Rulebook.new(rules))
    end
  end

  class Option < Struct.new(:first, :second)
    include Pattern
    def to_s
      [first,second].map{|pattern| pattern.bracket(precedence)}.join("|")
    end
    def precedence
      0
    end
    def to_nfa_runner
      start = Object.new
      first_nfa = first.to_nfa_runner
      second_nfa = second.to_nfa_runner
      new_rules =  [
        FA::Rule.new(start, nil, first_nfa.start_state),
        FA::Rule.new(start, nil, second_nfa.start_state)
      ]
      accept = first_nfa.accept_states + second_nfa.accept_states
      rules = first_nfa.rulebook.rules + second_nfa.rulebook.rules + new_rules
      NFA::Runner.new(start, accept, NFA::Rulebook.new(rules))
    end
  end

  class Repeat < Struct.new(:pattern)
    include Pattern
    def to_s
      pattern.bracket(precedence)+"*"
    end
    def precedence
      2
    end
    def to_nfa_runner
      nfa = pattern.to_nfa_runner
      rules = nfa.rulebook.rules + nfa.accept_states.map { |s|
        FA::Rule.new(s, nil, nfa.start_state)
      }
      NFA::Runner.new(nfa.start_state, nfa.accept_states, NFA::Rulebook.new(rules))
    end
  end

  context "Patterns" do
    asserts "can be built manually" do
      exp = Repeat.new(
        Option.new(
          Literal.new("x"),
          Concatenate.new(Literal.new("x"), Literal.new("y"))
        )
      )
      exp.inspect == "/(x|xy)*/"
    end

    context "Empty" do
      asserts "can be turned into an NFA" do
        Empty.new.to_nfa_runner.kind_of? NFA::Runner
      end
      asserts "Empty's NFA will accept the empty string" do
        Empty.new.matches?("")
      end
    end

    context "Literal" do
      asserts "can be turned into an NFA" do
        Literal.new("x").to_nfa_runner.kind_of? NFA::Runner
      end
      asserts "Literal's NFA will accept the character it was initialised with" do
        Literal.new("x").matches?("x")
      end
      asserts "Literal's NFA won't accept other characters than the one it was initialised with" do
        not Literal.new("x").matches?("y")
      end
    end

    context "Concatenate" do
      concat = Concatenate.new(Literal.new("x"), Literal.new("y"))
      asserts "#{concat.inspect} matches 'xy'" do
        concat.matches?("xy")
      end
      asserts "#{concat.inspect} does not match 'random'" do
        not concat.matches?("random")
      end
      chained = Concatenate.new(
        Literal.new("x"),
        Concatenate.new(Literal.new("y"), Literal.new("z")))
      asserts "can be chained so that #{chained.inspect} matches 'xyz'" do
        chained.matches?("xyz")
      end
    end

    context "Option" do
      option1 = Option.new(Literal.new("x"), Literal.new("y"))
      asserts "#{option1.inspect} matches 'x'" do
        option1.matches?("x")
      end

      option2 = Option.new(
        Concatenate.new(
          Literal.new("a"),
          Literal.new("b")),
        Literal.new("y"))
      asserts "#{option2.inspect} matches 'ab'" do
        option2.matches?("ab")
      end
      asserts "#{option2.inspect} matches 'y'" do
        option2.matches?("y")
      end
      asserts "#{option2.inspect} does not match 'random'" do
        not option2.matches?("random")
      end
    end

    context "Repeat" do
      repeat = Repeat.new(Literal.new("a"))
      asserts "#{repeat.inspect} will match 'a'" do
        repeat.matches?('a')
      end
      asserts "#{repeat.inspect} will match 'aaaaaaaaa'" do
        repeat.matches?('aaaaaaaaa')
      end
      asserts "#{repeat.inspect} will not match 'bb'" do
        not repeat.matches?('bb')
      end
    end

  end


end
