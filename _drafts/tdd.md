- side-effects are description
So, pure languages introduce a new step between compilation and execution.
When the IO operations are evaluated to a description of the actions, but not exectued yet.
"Totality checking is based on evalua-
tion, not execution. The result of totality checking an IO program, therefore,
tells you whether Idris will produce a finite sequence of actions, but nothing
about the runtime behavior of those actions."

- infinite arguments' list as function construction (with the construction of the type of the function)


-type holes


-use data type as intermediate representation (complex operations)
This gives a clean separation between the parsing of the format string and the process-
ing, much as we did when parsing the commands to the data store in chapter 4.

There are two main reasons for doing this:
 The meaning of String is not obvious from the type alone. The function type
Format -> Type has a more precise meaning than the function type String
-> Type because it’s clear that the input must be a format specification
rather than any String.
 Defining an intermediate data type gives us access to more interactive edit-
ing features, particularly case splitting.


-what i don't like
the output type of a function needs to be compelete
like you can't have as an output Vect n String
n should be specfied
This implies that when you use Vect in a data type and then you
want to get it, you need to store the type of its elements as well
as its length in the container to be able to write the getter output
type.


-Driven development
There’s still a problem here, however! This function can’t be total because not every
String is going to be parsable as a valid instance of the schema . Nevertheless, your
goal at the moment is merely to make the overall program type-check again. We’ll
return to this problem shortly.

To recap, you’ve updated the DataStore type to allow user-defined schemas, defining
it using a record to get field access functions for free, and you’ve updated the remain-
der of the program so that it now type-checks, inserting holes temporarily for the parts
that are more difficult to correct immediately.

KEEP RELOADING! While following this type-driven approach, you always have
a file that type-checks as far as possible. Here, rather than filling the hole
completely, you’ve written a small part of it with a new hole, and checked that
what you have type-checks before proceeding.




type:
define: this does not only work for algebric? data types, even for values of a string to match
refine:

-vs tdd
miss the most important test feature for me: selecting boundaries of the test subject.
(what exactly to test), although you can do that by importing the module in the REPL, you won't get the benefits of type checking there.
tdd works by eliminating duplication,
fisrt hard-code the solution as you knwo the input, then change the input and generalize the result. Then, in case you need, create an abstraction level.
typ dd. you should know least possible about the input, preferable use a type variable 'a', and pattern match what you know.
--> like, pattern match(extract), and refine, and where you are stuck, add a type parameters(an indirection level)
split type values and use holse when you don't know what to do yet


top-down
examples
mental load/consistent mental model
safe refactoring? with tools?