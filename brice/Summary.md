

The meaning of programs
========================

How do we define the meaning of a program? We need to assign meaning to the symbols used in the programming language. This can be done in one of several ways.

**Operational Semantics**

Define the meaning of a program by describing what are the practical effects of statements in the programming language using logical statements about the execution of a program. Essentially they define an interpreter for the language. Usually, formal definitions are in the form of a mathematical description using common mathematical constructs, such as functions, reduction rules or set operations. Interestingly, interpreters can be considered an operational semantic definition for a language too. This can be used to reason about interpreters in a formal way.

Operational semantics can be divided into a top down and bottom up approach.

The bottom up approach, also known as "structural operational semantics", "transition semantics" or "small-step semantics", describe how the individual steps of a computation take place in a computer-based system. For example, beta reduction in Lambda calculus. Small-step semantics describe intermediate stages of computations.

The top-down approach, known as "big-step semantics", "natural semantics", or "relational semantics" describe how the overall results of the executions are obtained. Formal semantics in the big-step style are often simpler and closer to the corresponding optimised compiler. Big-step semantics can be more intuitive.

Very roughly, we can think of small-step semantics as being iterative and big-step semantics as being recursive. A key example in operational semantics is the original McCarthy LISP paper that used the lambda calculus as a base.


 - **Denotational Semantics**
 (aka fixed point semantics, mathematical semantics)

 - **Axiomatic Semantics**
 assertions before and after a statement about the state of the system
 Preconditon and post conditions. good for verifying correctness of programs
