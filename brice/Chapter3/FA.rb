require "rubygems"
require "bundler/setup"
require "riot"

module FA
  class InvalidInputError < StandardError
  end

  class Rule < Struct.new(:state, :character, :next_state)
    def applies_to?(state, character)
      self.state == state  && self.character == character
    end
    def follow
      next_state
    end
    def inspect
      "<Rule #{state.inspect} --#{character}--> #{next_state.inspect}>"
    end
  end

  if __FILE__ == $0
    context "FA rule" do
      asserts("will apply to the character and state defined when created"){
        FA::Rule.new(1,"a", nil).applies_to?(1,"a")
      }

      asserts("will not apply to the wrong character"){
        not FA::Rule.new(1,"a", nil).applies_to?(1,"b")
      }

      asserts("will not apply to the wrong state"){
        not FA::Rule.new(1,"a", nil).applies_to?(2,"a")
      }
    end
  end
end
