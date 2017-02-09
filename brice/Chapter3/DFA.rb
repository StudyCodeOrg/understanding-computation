require "rubygems"
require "bundler/setup"
require "riot"

class InvalidInputError < StandardError
end

class FARule < Struct.new(:state, :character, :next_state)
  def applies_to?(state, character)
    self.state == state  && self.character == character
  end
  def follow
    next_state
  end
  def inspect
    "<FARule #{state.inspect} --#{character}--> #{next_state.inspect}>"
  end
end

class DFARulebook < Struct.new(:rules)
  def next_state(state, character)
    rule = rule_for(state, character)
    if rule.nil?
      raise InvalidInputError, "No rule for state[#{state}]<==#{character}"
    end
    rule.follow
  end
  def rule_for(state, character)
    rules.detect {|rule| rule.applies_to?(state, character)}
  end
end


class DFA < Struct.new(:current_state, :accept_states, :rulebook)
  def accepting?
    accept_states.include?(current_state)
  end
  def read_character(c)
    self.current_state = rulebook.next_state(current_state, c)
    self
  end
  def read_string(string)
    string.chars.each{ |chr|  read_character(chr)}
    self
  end
end

class DFARunner < Struct.new(:current_state, :accept_states, :rulebook)
  def dfa
    DFA.new(current_state, accept_states, rulebook)
  end
  def accepts?(string)
    begin
      self.dfa.read_string(string).accepting?
    rescue
      false
    end
  end
end


if __FILE__ == $0
  context "FA rule" do
    asserts("will apply to the character and state defined when created"){
      FARule.new(1,"a", nil).applies_to?(1,"a")
    }

    asserts("will not apply to the wrong character"){
      not FARule.new(1,"a", nil).applies_to?(1,"b")
    }

    asserts("will not apply to the wrong state"){
      not FARule.new(1,"a", nil).applies_to?(2,"a")
    }
  end

  context "Rulebook" do
    asserts ("can find the appropriate rule"){
      book = DFARulebook.new([
        FARule.new(1,"a", 2)
        ])
      book.next_state(1, "a") == 2
    }
  end


  context "DFA" do
    asserts("will accept when current state is in accept states"){
      DFA.new(1, [1], nil).accepting?
    }
    asserts("can read a character and change state"){
      dfa = DFA.new(1, [2], DFARulebook.new([FARule.new(1,"a",2)]))
      dfa.read_character('a').accepting?
    }
    asserts("will error out on incorrect input"){
      dfa = DFA.new(1, [2], DFARulebook.new([FARule.new(1,"a",2)]))
      dfa.read_character('b').accepting?
    }.raises(InvalidInputError)

    asserts("will read a string of characters to modify state"){
      dfa = DFA.new(1,[4], DFARulebook.new([
        FARule.new(1,"a", 2),
        FARule.new(2,"b", 3),
        FARule.new(3,"c", 4),
      ]))
      dfa.read_string("abc").accepting?
    }
  end


  context "DFA Runner" do
    asserts("will accept a valid string"){
      book = DFARulebook.new([
        FARule.new(1,"a", 2),
        FARule.new(2,"b", 3),
        FARule.new(3,"c", 4),
      ])
      runner = DFARunner.new(1,[4], book)
      runner.accepts?("abc")
    }

    asserts("will not accept an invalid string"){
      book = DFARulebook.new([
        FARule.new(1,"a", 2),
        FARule.new(2,"b", 3),
        FARule.new(3,"c", 4),
      ])
      runner = DFARunner.new(1,[4], book)
      not runner.accepts?("cba")
    }

    asserts("will not accept a string that leads to a non-accepting state"){
      book = DFARulebook.new([
        FARule.new(1,"a", 2),
        FARule.new(2,"b", 3),
        FARule.new(3,"c", 4),
      ])
      runner = DFARunner.new(1,[4], book)
      not runner.accepts?("ab")
    }
  end
end
