require "rubygems"
require "bundler/setup"
require "riot"
require_relative "FA"


module NFA
  class Rulebook < Struct.new(:rules)
    def next_states(states, input)
      states.flat_map{ |state|
         rules.select{|rule|
           rule.applies_to?(state, input)
         }.map(&:follow)
      }.to_set
    end
    def follow_free_moves(states)
      states = states.to_set
      more_states = next_states(states, nil)
      if more_states.subset?(states)
        states
      else
        follow_free_moves(states+more_states)
      end
    end
  end

  class NFA < Struct.new(:current_states, :accept_states, :rulebook)
    def current_states
      if rulebook
        rulebook.follow_free_moves(super)
      else
        super
      end
    end
    def accepting?
      (self.current_states & accept_states).any?
    end
    def read_input(input)
      self.current_states = rulebook.next_states(current_states, input)
      self
    end
    def read_string(xs)
      xs.chars.each{|input| self.read_input(input)}
      self
    end
  end

  class Runner < Struct.new(:start_state, :accept_states, :rulebook)
    def nfa
      NFA.new(Set[start_state], accept_states, rulebook)
    end
    def accepts?(string)
      self.nfa.read_string(string).accepting?
    end
  end

  if __FILE__ == $0

    test_rulebook = Rulebook.new([
      FA::Rule.new(1,"a",1),
      FA::Rule.new(1,"b",1),
      FA::Rule.new(1,"b",2),
      FA::Rule.new(2,"a",3),
      FA::Rule.new(2,"b",3),
      FA::Rule.new(3,"a",4),
      FA::Rule.new(3,"b",4)
    ])

    context "NFA Rulebook" do
      asserts "will return multiple states if the rules allow" do
        test_rulebook.next_states(Set[1],"b").size > 1
      end
      asserts "will return the correct set of states" do
        test_rulebook.next_states(Set[1],"b") == Set[1,2]
      end
    end

    context "NFA" do
      asserts "will be accepting if any of the accept states are possible current states" do
        NFA.new([1,2], [2], nil).accepting?
      end
      asserts "will not be accepting if none of the accept states are possible current states" do
        not NFA.new([3,4], [2], nil).accepting?
      end
      asserts "can read a character and change state" do
        NFA.new([1], [2], test_rulebook).read_input("b").accepting?
      end
      asserts "can read a sequence of input and change state" do
        NFA.new([1], [4], test_rulebook).read_string("bab").accepting?
      end
      asserts "will accept a sequence that requires nondeterminism" do
        NFA.new([1], [4], test_rulebook).read_string("bbbbbbbbb").accepting?
      end
    end

    context "NFA Runner" do
      asserts "will accept a valid string" do
        Runner.new(1, [4], test_rulebook).accepts?("bbbbbbbb")
      end
    end

    context "ε-NFA rulebook" do
      asserts "An ε-NFA rulebook can be created with empty input requirements" do
        book = Rulebook.new([
          FA::Rule.new(1,nil,2),
          FA::Rule.new(1,nil,3)
        ])
      end
      asserts "an ε-NFA rulebook can follow free moves and return a new set of states" do
        book = Rulebook.new([
          FA::Rule.new(1,nil,2),
          FA::Rule.new(1,nil,3)
        ])
        book.follow_free_moves([1]) == Set[1,2,3]
      end
      asserts "an ε-NFA rulebook will follow a chain of free moves" do
        book = Rulebook.new([
          FA::Rule.new(1,nil,2),
          FA::Rule.new(2,nil,3),
          FA::Rule.new(3,nil,4)
        ])
        book.follow_free_moves([1]) == Set[1,2,3,4]
      end
    end

    context "ε-NFA" do
      asserts "will take into account free moves when getting current states" do
        nfa = NFA.new([1], [4], Rulebook.new([
          FA::Rule.new(1,nil,2),
          FA::Rule.new(2,nil,3),
          FA::Rule.new(3,nil,4)
        ]))
        nfa.current_states == Set[1,2,3,4]
      end
    end
  end
end
