# Notes on Chapter 1

## Syntax gotchas

Note that the following

    def a(x)
      x*x
    end

Is not a function! It's actually a **method** on the top level `Object`.

## Procs, Lambdas and Blocks

Differences between Lambdas and procs include:

 - [Lambdas check their arguments, Procs don't][1]
 - [Lambdas return back to the original context, Procs end the original context and return from it][2]



[1]: http://stackoverflow.com/questions/1740046/
[1]: http://stackoverflow.com/questions/1740046/
