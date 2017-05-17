require "rubygems"
require "bundler/setup"
require "riot"
require "treetop"
require_relative "FA"
require_relative "DFA"
require_relative "NFA"


class NFASimulation < Struct.new(:nfa_runner)
  def next_state(state, character)
    nfa_runner.nfa(state).read_input(character).current_states
  end

  def rules_for(state)
    nfa_runner.rulebook.alphabet.map { |character|
      FA::Rule.new(state, character, next_state(state, character)) }
  end
end


if __FILE__ == $0
  testbook = NFA::Rulebook.new([
    FA::Rule.new(1, 'a', 1),
    FA::Rule.new(1, 'a', 2),
    FA::Rule.new(1, nil, 2),
    FA::Rule.new(2, 'b', 3),
    FA::Rule.new(3, 'b', 1),
    FA::Rule.new(3, nil, 2)
  ])
  runner = NFA::Runner.new(1, [3], testbook)

  context "NFASimulation" do
    asserts "will accept a runner on cosntruction" do
      NFASimulation.new(runner)
    end
    asserts "will return the correct metatstate when stepped once" do
      NFASimulation.new(runner).next_state(Set[1,2], 'a') == Set[1,2]
    end

    asserts "will return the correct metastate when stepped with defined starting states" do
      NFASimulation.new(runner).next_state(Set[3, 2], 'b') ==Set[1, 3, 2]
    end
  end
end
