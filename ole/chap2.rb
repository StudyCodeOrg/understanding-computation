class Number < Struct.new(:value)
	def to_s
		value.to_s
	end
	def inspect
		"<<#{self}>>"
	end
	def reducible?
		false
	end
end
class Add < Struct.new(:left, :right)
	def to_s
		"#{left} + #{right}"
	end
	def inspect
		"«#{self}»"
	end
	def reducible?
		true
	end
	def reduce(environment)
		if left.reducible?
			Add.new(left.reduce(environment), right)
		elsif right.reducible?
			Add.new(left, right.reduce(environment))
		else
			Number.new(left.value + right.value)
		end
	end
end
class Multiply < Struct.new(:left, :right)
	def to_s
		"#{left} * #{right}"
	end
	def inspect
		"«#{self}»"
	end
	def reducible?
		true
	end
	def reduce(environment)
		if left.reducible?
			Multiply.new(left.reduce(environment), right)
		elsif right.reducible?
			Multiply.new(left, right.reduce(environment))
		else
			Number.new(left.value * right.value)
		end
	end
	
end

Add.new(
Multiply.new(Number.new(1), Number.new(2)),
Multiply.new(Number.new(3), Number.new(4))
)

Number.new(5)


def reducible?(expression)
	case expression
	when Number
	false
	when Add, Multiply
		true
	end
end

Number.new(1).reducible?

Add.new(Number.new(1), Number.new(2)).reducible?

expression =
	Add.new(
		Multiply.new(Number.new(1), Number.new(2)),
		Multiply.new(Number.new(3), Number.new(4))
		)


#expression.reducible?
#expression = expression.reduce
#expression.reducible?
#expression = expression.reduce
#expression.reducible?
#expression = expression.reduce


class Machine < Struct.new(:statement, :environment)

	def step
		self.statement, self.environment = statement.reduce(environment)
	end

	def run
		while statement.reducible?
			puts "#{statement}, #{environment}"
			step
		end
		puts "#{statement}, #{environment}"
	end
end

Machine.new(
	Add.new(
		Multiply.new(Number.new(1), Number.new(2)),
		Multiply.new(Number.new(3), Number.new(4))
		)
	).run

class Boolean < Struct.new(:value)
	def to_s
		value.to_s
	end
	def inspect
		"<<#{self}>>"
	end
	def reducible?
		false
	end
end

class LessThan < Struct.new(:left, :right)
	def to_s
		"#{left} < #{right}"
	end
	def inspect
		"<<#{self}>>"
	end
	def reducible?
		true
	end
	def reduce(environment)
		if left.reducible?
			LessThan.new(left.reduce(environment), right)
		elsif right.reducible?
			LessThan.new(left,right.reduce(environment))
		else
			Boolean.new(left.value < right.value)
		end
	end
end

Machine.new(
	LessThan.new(Number.new(5), Add.new(Number.new(2), Number.new(2)))
	).run


class Variable < Struct.new(:name)
	def to_s
		name.to_s
	end
	def inspect
		"<<#{self}>>"
	end
	def reducible?
		true
	end
	def reduce(environment)
		environment[name]
	end
end

Machine.new(
	Add.new(Variable.new(:x), Variable.new(:y)),
	{ x: Number.new(3), y: Number.new(4) }
	).run


class DoNothing
	def to_s
		'do-nothing'
	end
	def inspect
		"<<#{self}>>"
	end
	def ==(other_statement)
		other_statement.instance_of?(DoNothing)
	end
	def reducible?
		false
	end
end

class Assign < Struct.new(:name, :expression)
	def to_s
		"#{name} = #{expression}"
	end
	def inspect
		"<<#{self}>>"
	end
	def reducible?
		true
	end
	def reduce(environment)
		if expression.reducible?
			[Assign.new(name, expression.reduce(environment)), environment]
		else
			[DoNothing.new, environment.merge({ name => expression })]
		end
	end
end


statement = Assign.new(:x, Add.new(Variable.new(:x), Number.new(1)))
environment = { x: Number.new(2) }

m = Machine.new(
Assign.new(:x, Add.new(Variable.new(:x), Number.new(1))),
{ x: Number.new(2) }
)

m.run()



class If < Struct.new(:condition, :consequence, :alternative)
	def to_s
		"if (#{condition}) { #{consequence} } else { #{alternative} }"
	end
	def inspect
	"<<#{self}>>"
	end
	def reducible?
		true
	end
	def reduce(environment)
		if condition.reducible?
			[If.new(condition.reduce(environment), consequence, alternative), environment]
		else
			case condition
				when Boolean.new(true)
				[consequence, environment]
				when Boolean.new(false)
				[alternative, environment]
			end
		end
	end
end

Machine.new(
If.new(
Variable.new(:x),
Assign.new(:y, Number.new(1)),
Assign.new(:y, Number.new(2))
),
{ x: Boolean.new(true) }
).run


class Sequence < Struct.new(:first, :second)
	def to_s
		"#{first}; #{second}"
	end
	def inspect
		"«#{self}»"
	end
	def reducible?
		true
	end
	def reduce(environment)
		case first
		when DoNothing.new
			[second, environment]
		else
			reduced_first, reduced_environment = first.reduce(environment)
			[Sequence.new(reduced_first, second), reduced_environment]
		end
	end
end

Machine.new(
Sequence.new(
Assign.new(:x, Add.new(Number.new(1), Number.new(1))),
Assign.new(:y, Add.new(Variable.new(:x), Number.new(3)))
),
{}
).run

class While < Struct.new(:condition, :body)
    def to_s
        "while (#{condition}) { #{body} }"
    end
    def inspect
        "«#{self}»"
    end
    def reducible?
        true
    end
    def reduce(environment)
        [If.new(condition, Sequence.new(body, self), DoNothing.new), environment]
    end
end

Machine.new(
    While.new(
        LessThan.new(Variable.new(:x), Number.new(5)),
        Assign.new(:x, Multiply.new(Variable.new(:x), Number.new(3)))
    ),
    { x: Number.new(1) }
).run

