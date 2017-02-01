require "rubygems"
require "bundler/setup"
require "riot"

square1 = -> x {x*x}
square2 = proc {|n| n*n}
square3 = lambda {|n| n*n}

# Note well, this is a **method** on the `main` object
def square4(x)
  x*x
end
# We need to bind it before referencing it, otherwise,
# having it referenced in an array like:
#
#     [ square1, ... , square4 ]
#
# Will attempt to call the method without arguments.
# So we wrap it with a `Method` object using the
# `method` method. Confused yet?
square4 = method(:square4)

[square1, square2, square3, square4].each do |fn|
  context "Function #{fn}" do
    setup(fn)
    [1,2,3,4,5,6,7].each do |n|
      asserts("called with #{n}") { fn.call(n) }.equals(n*n)
    end
  end
end
