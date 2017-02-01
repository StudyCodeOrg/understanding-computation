# Notes on Chapter 1

## Syntax gotchas

### Methods vs functions

Note that the following

    def a(x)
      x*x
    end

Is not a function! It's actually a **method** on the top level `Object`.

It can be converted to a similar object to a proc or a lambda by wrapping around a `Method` object:

    a = method(:a)

### Lambdas don't take Blocks

For example, this code won't work:

    a = -> { puts yield(2)}
    a {|n| n-1} #=> NoMethodError: undefined method `a' for main:Object

## Procs, Lambdas and Blocks

Differences between Lambdas and procs include:

 - [Lambdas check their arguments, Procs don't][1]
 - [Lambdas return back to the original context, Procs end the original context and return from it][2]



[1]: http://stackoverflow.com/questions/1740046/
[2]: http://stackoverflow.com/questions/1740046/
