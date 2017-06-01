The meaning of programs
========================

How do we define the meaning of a program? We need to assign meaning to the symbols used in the programming language. This can be done in one of several ways.

**Operational Semantics**

Define the meaning of a program by describing what are the practical effects of statements in the programming language using logical statements about the execution of a program. Essentially they define an interpreter for the language. Usually, formal definitions are in the form of a mathematical description using common mathematical constructs, such as functions, reduction rules or set operations. Interestingly, interpreters can be considered an operational semantic definition for a language too. This can be used to reason about interpreters in a formal way.

Operational semantics can be divided into a top down and bottom up approach.

The bottom up approach, also known as "structural operational semantics", "transition semantics" or "small-step semantics", describe how the individual steps of a computation take place in a computer-based system. For example, beta reduction in Lambda calculus. Small-step semantics describe intermediate stages of computations.

The top-down approach, known as "big-step semantics", "natural semantics", or "relational semantics" describe how the overall results of the executions are obtained. Formal semantics in the big-step style are often simpler and closer to the corresponding optimised compiler. Big-step semantics can be more intuitive.

Very roughly, we can think of small-step semantics as being iterative and big-step semantics as being recursive. A key example in operational semantics is the original McCarthy LISP paper that used the lambda calculus as a base.

 **Denotational Semantics**

 Denotational semantics, also known as fixed point semantics, or mathematical semantics, are a way of giving meaning to a language by directly relating it to an existing language with known meaning. For example, mathematical syntax. This can also be another programming language. An interpreter or compiler can be considered a form of denotational semantics. Many actual languages are specified by implementation, for example, both Python and Ruby are defined by a standard implementation.

 **Axiomatic Semantics**

 Axiomatic semantics define the meaning of symbols and expressions in a language by making assertions about the state of the system before and after a statement. By defining pre-conditions and post-conditions. Axiomatic semantics are a great way for verifying correctness of programs. In fact, Unit Tests can be considered Axiomatic semantics for programs we write. Some languages have built in contracts that act as axiomatic semantics for programs (Eiffel?), while some standard of stricter subsets of languages (Secure subsets of C, for example) use ideas from Axiomatic Semantics to constrain the original less secure language.

You can find more detailed information [on stackexchange](http://cs.stackexchange.com/questions/43294/difference-between-small-and-big-step-operational-semantics).
