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

  def states_and_rules(states = Set[nfa_runner.nfa().current_states])
    rules = states.flat_map {|state| rules_for(state)}
    more_states = rules.map(&:follow).to_set

    if more_states.subset?(states)
      [states, rules]
    else
      states_and_rules(states+more_states)
    end
  end

  def to_dfa()
    start_state = nfa_runner.nfa().current_states
    states, rules = states_and_rules
    accept_states = states.select { |s| nfa_runner.nfa(s).accepting? }
    DFA::DFA.new(start_state, accept_states, DFA::Rulebook.new(rules))
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

    [
      [Set[1,2], 'a', Set[1,2]],
      [Set[1,2], 'b', Set[3,2]],
      [Set[3,2], 'b', Set[1,2,3]],
      [Set[1,2,3], 'b', Set[1,2,3]],
      [Set[1,2,3], 'a', Set[1,2]],
    ].each do |starting_metastate, input_char, expected_metastate|
      asserts("With a starting metastate of #{starting_metastate.inspect} and an input of #{input_char}, the next metatstate") {
        NFASimulation.new(runner).next_state(starting_metastate, input_char)
      }.equals(expected_metastate)
    end

    asserts "can return the states of an NFA" do 
      states, rules = NFASimulation.new(runner).states_and_rules()
      states == Set[
        Set[1,2],
        Set[2,3],
        Set[],
        Set[1,2,3]
      ]
    end

    asserts "can return the rules of an NFA" do
      states, rules = NFASimulation.new(runner).states_and_rules()
      rules == [
        FA::Rule.new(Set[1,2], 'a', Set[1,2]),
        FA::Rule.new(Set[1,2], 'b', Set[2,3]),
        FA::Rule.new(Set[3,2], 'a', Set[]),
        FA::Rule.new(Set[3,2], 'b', Set[1,2,3]),
        FA::Rule.new(Set[], 'a', Set[]),
        FA::Rule.new(Set[], 'b', Set[]),
        FA::Rule.new(Set[1,2,3], 'a', Set[1,2]),
        FA::Rule.new(Set[1,2,3], 'b', Set[1,2,3])
      ]
    end

    asserts "can create a valid DFA" do
      dfa = NFASimulation.new(runner).to_dfa()
      not DFA::Runner.new(dfa).accepts?('aaa')
    end

  end
end
