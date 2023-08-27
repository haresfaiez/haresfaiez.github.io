---
layout:   post
comments: true
title:    "Level up your property based testing library"
date:     2023-08-27 12:02:00 +0100
tags:     featured
---

In the [previous post](/2023/05/21/how-to-write-a-property-based-testing-library-erlang-vs-haskell.html),
I talked about implementing a minimal property-based testing library.
You can check it if you want to know how QuickCheck and PropEr work.
This post is a follow-up where I'll try to explain how some auxiliary features
are implemented. Keep in mind that the code snippets are simplifications of the original ones.

## Generating functions with Quickcheck

Quickchek can check [higher-order functions](https://en.wikipedia.org/wiki/Higher-order_function).
These are functions that take other functions as arguments
or that return new functions as results.
Let's say we have a function `foldBelowThreshold`.
It takes a function `Integer -> Integer`, an array of integers,
and a threshold number.
It applies the function to each element of the array then it sums the results.
It returns the sum only if it's smaller than the threshold.

A property for `foldBelowThreshold` can be:

```haskell
propCheckBelowThreshold :: Fun Integer Integer -> Bool
propCheckBelowThreshold (Fun _ f) = foldBelowThreshold(f, [8, 23, 3], 200) < 200
```

To check this, QuickCheck generates many functions `f`
and checks the property with each of them.

Another example from the library tests is `prop`:

```haskell
prop :: Fun String Integer -> Bool
prop (Fun _ f) = f "snake" == f "tiger" || f "tiger" == f "elephant"
```

It checks whether every function `f :: String -> Integer`
that takes a string and returns an integer
satisfies an equality check.

Running `quickCheck` gives us:

```console
*** Failed! Falsified (after 3 tests and 134 shrinks):
{"elephant"->1, "snake"->1, _->0}
```

The counterexample is a function that returns `1` when the input is `"elephant"`
or `"snake"`, and `0` when it's `"tiger"`.

### The philosophy

A function is a set of input/output pairs, or range/domain pairs if we are
to use the right terms.
Creating a new function is all about generating a new such set.
This set can be very big when the input space is huge.
Think about a `String` or a list as an input type.
What we can do is to partition the space. We say that one-character strings
will return `1`. Two-character strings will return `4`,
and so on...

Creating functions this way won't be practical enough for testing.
It's too simple to expose bugs.
We need variability.
QuickCheck simplifies these types using a divide-and-conquer approach.
A string is a list of characters.
A character can be represented as a `Word8`, which is between `0` and `255`.
`Word8` is an 8-bit bounded unsigned integer that can be mapped to an integer.
It might not be mapped to a static integer, but it can be an input to a random
numbers generator (and yes [random number generators need variability too](https://www.tweag.io/blog/2020-06-29-prng-test/)).

Given a string, a generated function will go through it character by character.
Each character contributes to the return value.
A character is mapped to a `Word8`.
This number increases the variability of the return value.

We reduce the number of output values during shrinking
by making more and more inputs return the same output.
A maximally shrunk function will return `0` for every value of `String`.
Shrinking the function is all about shrinking the table
that maps every input to an output.

A function that takes a one-character string can be thought of as
a function that takes a character and a table of characters/outputs.
It looks for the character in the table and returns the value associated with it.

The same function, when it takes a two-character string, can be thought
of as a function that also takes a one-character string (the first one) and a table
of characters/outputs.
It does the same.
It looks for the occurrence of the one-character string in the table
and it returns the value associated with it.
But this time, the value will be itself a table.
It's the table that we pass to the function that accepts one-character strings.
Same for multiple-character strings, the function is always the same. It's the table that differs.

To implement all this, QuickCheck structures functions using the required type.
`f`, from the definition of `prop` above, is the reification
of a function structure.
And then to shrink a function, we shrink the structure.
We pass a null table (a table that returns the same result for all the characters)
instead of the multi-output normal table.
A shrunk function structure will produce a function that ignores the last characters of the string.
`f "Hello World!"` will be the same as `f "Hello"`.

If the function continues failing as the structure shrinks,
we'll end up with a function structure
that is equivalent to the null table.
It'll always return `f ""` for any string.

### Generating a function

The function operator in Haskell is `->`.
We can write a function type as `a -> b` or as `((->) a) b`.
For QuickCheck to be able to create instances for a type,
the latter should implement the class `Arbitrary`.
It should define two methods `arbitrary` and `shrink` that create and shrink instances.

`a -> b` implements `Arbitrary`:

```haskell
instance (CoArbitrary a, Arbitrary b) => Arbitrary (a -> b) where
  arbitrary = do
    eval <- delay
    return (liftM eval (\a -> coarbitrary a arbitrary))
```

The implementation creates a function (`\a -> ...`) that builds a `b` generator
using `arbitrary`. Then, it calls `coarbitrary a` to build another `b` generator.

This inlined function, whose type is `a -> Gen b` is lifted using `eval` into a
function whose type is `a -> b`.

`delay` generates functions of the type `Gen b -> b`:

```haskell
delay :: Gen (Gen b -> b)
delay = MkGen (\r n g -> unGen g r n)
```

`eval` is one such function:

```haskell
eval :: Gen b -> b
eval = \g -> unGen g aRandomNumGenerator aSize
```

This is the value of `eval` we're using for the lifting with `liftM`.
If we write `a -> w` as `(((->) a) w)`, we can consider `((->) a)` a Monad
whose type argument is `w`.

The type of `liftM` is:

```haskell
liftM :: (Gen b -> b) -> (((-> ) a) Gen b) -> ((-> a) b)
```

We can simplify the notation:

```haskell
liftM :: (Gen b -> b) -> (a -> Gen b) -> (a -> b)
```

To sum up, we create a `Gen b` then we integrate a value of `a` into it.
We make it depends on `a`.
We define a function `a -> Gen b` in-line to provide the value of `a`.
The value of `a` will be provided by the user.
This value will be used to create a value of `b` through `Gen b`.
We transform `a -> Gen b` into `a -> b`.
Then, we call `return` to make it `Gen (a -> b)`.

The last two steps are kind of "type plumbing".
We're just fitting the structure to the type.
We "delay" the evaluation of `b` from getting `a` first
then getting a random number generator,
to getting a random number generator, a size, and then a value of `a`.

This idea of delaying evaluation is widespread in functional codebases.
It's implemented either by changing the order of the arguments
or by introducing proxy functions,
that is functions that take some arguments and pass them as they are to another function.

It's quite an interesting pattern of state encapsulation.
Have the values, do not use them directly (keep them attached to a monad for example),
wait for a trigger (another value for example), then inject and evaluate.
You can also create other "delays" or wrap the whole process inside other monads.
Such monads can modify the encapsulated values,
or they can transform/ignore the trigger we're waiting for.

It's interesting also to compare this to the OOP idioms of implementing state encapsulation.
There, we keep the state local and we handle async messages.
The boundaries are explicit.
And whoever manages the state decides what should be done:
Fewer things move under the carpet, which might mean more code,
but also fewer structure transformations that serve only the purpose of adhering to an interface,
which means less time debugging and exploring the logic.

It's a question of how we want to handle the logic
and the representation that falls outside
our mental model and outside the implicit design decisions we make.

Back to coding!

To implement what we talked about previously, `a` implements `CoArbitrary`.
The motivation behind `CoArbitrary a` is to create functions `a -> b`
that return different output values for different input values.

`CoArbitrary a` should define:

```haskell
coarbitrary :: a -> Gen b -> Gen b
```

No matter which type `b` is,
`coarbitrary` takes a value of `a` and a generator of `b`.
It returns a new generator of `b` that assimilates `a`.

A question might arise here. If we already have the value of `a`,
and we want the value of `b` for it,
why isn't the signature:

```haskell
coarbitrary :: a -> Gen b -> b
```

?

and why not:

```haskell
coarbitrary :: Gen b -> a -> b
```

?

The return type is `Gen b` instead of `b` because `a` alone
is not enough to create `b`.
We need to generate a `b` value from the `b` generator.
The generation requires a random number generator.

It's the delay pattern again.

If we want a `b` result, we can define `coarbitrary` as:

```haskell
coarbitrary :: a -> QCGen -> Gen b -> b
```

With this definition, `coarbitrary` needs to peek inside
`Gen` definition and call `unGen` to generate a `b`.
This is more-or-less what `delay` and `eval` are doing.
They're providing `b` generator with a random number
generator and a size.

All `coarbitrary` definitions for the types handled by QuickCheck
follow the same pattern.
Each tries to deconstruct a given value recursively.

During each recursive iteration, it returns:

```haskell
variant n (coarbitrary simplifiedValue givenGenerator)
```

The last iteration returns:

```haskell
variant n givenGenerator
```

`simplifiedValue` is the next simplified value.
Given an array, the definition takes the head and calls itself with the tail.
Given an `Either` or a `Maybe`, it calls itself with the wrapped value.

`n` is usually `0` or `1`. It depends on the variants of the type.
For `Either`, it's `0` for `Left` and `1` for `Right`.
For a list, it's `0` for an empty list and `1` for a non-empty one.

The documentation says:

```haskell
  -- You should use 'variant' to perturb the random generator;
  -- the goal is that different values for the first argument will
  -- lead to different calls to 'variant'.
  -- ...
  -- The logic behind 'variant'. Given a random number seed, and an integer, uses
  -- splitting to transform the seed according to the integer.
```

It's defined as:

```haskell
variant :: Integral n => n -> Gen a -> Gen a
variant k (MkGen g) = MkGen (\r n -> g (integerVariant (toInteger k) $! r) n)
```

The body of `variant` creates a generator whose `unGen` returns
a value generated by the given generator `g`.
The tricky part is the generation of the random number generator
that'll be passed.

It's not the regular generator.

`integerVariant` takes the variation number and the regular generator.

```console
 -- The $! operator ensures that the second argument r is evaluated to weak head
 -- normal form (WHNF) before being passed to the function integerVariant.
 -- This means that the value of r is fully evaluated (to the outermost constructor)
 -- before the function is applied.
```

Making sure `r`, the random number generator, is evaluated to WHNF guarantees
that the same string will give the same returned value.
Splitting it in the same way will give the same random numbers.

`integerVariant` documentation says:

```haskell
  -- Use one bit to encode the sign, then use Elias gamma coding
  -- (https://en.wikipedia.org/wiki/Elias_gamma_coding) to do the rest.
  -- Actually, the first bit encodes whether n >= 1 or not;
  -- this has the advantage that both 0 and 1 get short codes.
```

A random number generator can be split into two generators.
This is a feature of
[RandomGen](https://hackage.haskell.org/package/random-1.1/docs/System-Random.html#t:RandomGen)
in Haskell.

Elias gamma coding works for numbers greater or equal to `1`.
`integerVariant` uses `1 - n` if the value of `n` we pass in the first
argument is less than `1`.

The goal of this function is to inject an amount of variability
equivalent to the number we pass in.
Elias gamma coding transforms a number into a bit stream.
The function takes the given generator and follows the bit stream,
splitting the generator for each bit, taking the left split
if the bit is `0`, and taking the right split if it's `1`.
The last split is returned.

### Structuring a function

`Function a` is a class of types `a` that can be an input to a function structure.

To instantiate `Function` for a type `a`, we define a function named `function` for it.
It'll structure a function `a -> b` into `a :-> b`:

```haskell
function :: (a -> b) -> (a :-> b)
```

`b` can be any type. It does not matter as long as we can calculate
it by providing the right value of `a` to the input function `a -> b`.

`:->` is a data type that takes two type arguments, `a` and `b`.
We can write it either as `a :-> b` or as `((:-> ) a) b`.
The result is a structure `a :-> b` that generates as many functions `a -> b` as we want.

QuickCheck offers six constructors to create values of such type:

```haskell
data a :-> c where
  Pair  :: (a :-> (b :-> c)) -> ((a,b) :-> c)
  (:+:) :: (a :-> c) -> (b :-> c) -> (Either a b :-> c)
  Unit  :: c -> (() :-> c)
  Nil   :: a :-> c
  Table :: Eq a => [(a,c)] -> (a :-> c)
  Map   :: (a -> b) -> (b -> a) -> (b :-> c) -> (a :-> c)
```

If `a` is `String` and `c` is `Integer`,
we can create a value of `String :-> Integer`:

```haskell
Table [("Hello", 5), ("world", 8)]
```

This is not how QuickCheck structures a function `String :-> Integer`.
A function structure can be a huge recursive construct
where the leaves are non-recursive values created with `Unit`, `Nil`, or `Table`.

The library structures a function that takes a `String` and returns an `Integer` as a `Map`.

The `Map` constructor maps a structure `a :-> b`
to a new one `y :-> b`. `y` is a different, but equivalent, type that represents `a`.
`String :-> Integer` is mapped to `Either () (Char, String) :-> Integer`.
The left side of `Either` handles empty strings.
Its right side handles non-empty ones.
A string is represented as a pair of its first character and its remaining characters.

You can take a look again at the definition of `Map` constructor above.
We create it by providing a function `String -> Either () (Char, String)`,
a function `Either () (Char, String) -> String`,
and a structure `Either () (Char, String) :-> Integer`.

We create a function structure by transforming a function `b -> c` into `b :-> c`.
Quickcheck needs a way to map a `String` into an `Either` value.
It uses this mapping during reification. It calls the reification of `b :-> c`
with the result of transforming a value of `a` using the first function.

But, the function we want to structure initially is `String -> Integer`.
Even the function `Either () (Char, String) -> Integer` should get its
returned value from the initial one.
That's why we pass the second function. Internally, the function we use
to create the structure `b :-> c` maps an `Either` to a `String` and calls
the initial function.

To structure `Either () (Char, String) :-> Integer`,
`function` structures each of `()` and `(Char, String)` separately.
It builds two structures: one from an empty string to an integer  `() :-> Integer`,
and one from a non-empty string to an integer `(Char, String) :-> Integer`.
Then, it joins them with a `:+:` constructor.

That is:

```haskell
structureOfEmptyString :+: structureOfNonEmptyString
```

To structure `() :-> Integer`,
`function` createas uses `Unit`, that is `Unit f ()`.
`f` is the function `String -> Integer`, or `a -> b`, we pass to `function` in the beginning.

To structure`(Char, String) :-> Integer`, `function` creates a `Pair` structure.
As the definition of `Pair` states, we need a structure `Char :-> (String :-> Integer)` with three types.

Such a wrapped structure is created with `Table` constructor.
The elements are pairs.
Each left side contains a character between `Word8` `minBound` and its `maxBound`.
Each right side contains a structure `String :-> Integer`.

This latter is the same `Map` structure we started with in the first place.
Again, we'll map it into a structure `Either () (Char, String) :-> Integer`.
Then, we'll split this one into `() :-> Integer` and `(Char, String) :-> Integer`.
The difference is in the function we'll use now to build these two structures.

During the first iteration, it was `f (h b)`. `f` is the initial function we generate
and pass `function`. `h` transforms an `Either () (Char, String)` into a `String`.
`b` is the input of the function `Either () (Char, String) -> Integer`.

Here, it'll be `f1 (h b)`. `h` and `b` are the same.
`f1` is `currentCharacter -> f (firstCharcter ++ currentCharacter)`.
`firstCharacter` is the character we used in the previous structure.
That is the first character of the string.

The structure we get at the end is huge and recursive, an infinite big tree.
Each character creates a table with all the possible characters.
And inside each element of that table, there's a new table,
also with all possible characters.
And so it on.

### Reifying a function structure

`Fun` is defined as:

```haskell
data Fun a b = Fun (a :-> b, b, Shrunk) (a -> b)
```

`mkFun` creates `Fun` values:

```haskell
mkFun :: (a :-> b) -> b -> Fun a b
mkFun p d = Fun (p, d, NotShrunk) (abstract p d)
```

The first argument `(a:->b, b, Shrunk)` is used to display
the function and to orient shrinking.
We need it because `a -> b` is not showable.

The second argument is the reified function.
We extract and use it in the body of the property.
`abstract` takes a function structure `a :-> b`
and a value of the return type `b`.
It returns a function `a -> b`.

`abstract`, when the given a `Map` structure, is:

```haskell
abstract (Map g _ p) d x = abstract p d (g x)
```

`Map` is a bridge between the function we want to structure
and an equivalent function that QuickCheck knows how to structure.

`\x -> abstract p d (g x)` is the function returned by `abstract p d`.
It takes a string `x` and returns an integer.
`g x` maps the string input into a value `Either () (Char, String)`.
If `x` is the string `"go!"`, `g x` will be `Right ("g", "o!")`.
If it's an empty string, `g x` will be `Left ()`.
`abstract p d` is the function that reifies the structure `Either () (Char, String) :-> Integer`.
It's a function that takes an `Either () (Char, String)` and returns an integer.

For `:+:`, which structures a function that takes a value of `Either`, `abstract` is:

```haskell
abstract (p :+: q)   d exy   = either (abstract p d) (abstract q d) exy
```

It depends on `exy`, the value of type `Either`.
If it's `Left`, the first structure is reified.
If it's `Right`, the second one is picked for reification.

For a `Pair`, it's:

```haskell
abstract (Pair p)    d (x,y) = abstract (fmap (\q -> abstract q d y) p) d x
```

The type of `p` is `a :-> (b :-> c)`.
The body first reifies the inner structure `b :-> c` and gets a function `b -> c`.
Then, it reifies the structure `a :-> (b -> c)` and gets a function `a -> (b -> c)`.

The implementation of `fmap` for `:->` applies the function to the second argument.
Using `fmap f` on a structure `a :-> b` gives a result of type `a :-> (f b)`.
`fmap (\q -> abstract q d y) p` takes care of the inner function.

Other implementations are:

```haskell
abstract (Unit c)    _ _     = c
abstract Nil         d _     = d
abstract (Table xys) d x     = head ([y | (x',y) <- xys, x == x'] ++ [d])
```

The second argument `d`, a value of the return type,
is used only when the structure is `Nil`.
A nil structure returns a randomly generated value.

For `Unit`, the value inside the structure is returned no matter what the input is.

For `Table`, we search for a pair whose left side is the input and we return its right side.

Initially (before shrinking),
the function returned by `abstract` is equivalent to the generated function `f`.

For our structure `String :-> Integer`, the reified function will be a similarly huge recursive structure.
But, as only the needed path is evaluated, for the input `"go!"`, the runtime evaluation will be:

```haskell
result = (\char3Input -> char2Input -> char1Input -> f (char1Input:(char2Input:(char3Input:[])))) "!" "o" "g"
```

This is because inside `abstract`, when the structure is `Pair`, the inner structure
is reified and called with the tail of the string (`y` in the definition).
Then the outer structure is reified and called with the first character of the string,
`x` in the definition.

This is another occurrence of the delay pattern.
Here it's implemented with recursion instead of monads.
The evaluation is delayed until the characters of the string are collected.
When all characters are there, the function is evaluated.

### Checking a property (How it all fits together)

For QuickCheck to generate an instance of `Fun` for testing,
`Fun` needs to instantiate the class `Arbitrary`.

It should provide:

* a function `arbitrary` that returns a generated instance `Gen (Fun a b)`
* a function `shrink` that returns a list of simplified
`Fun` values given a `Fun` instance that fails the property.

The complete definition of `Arbitrary` for `Fun` is:

```haskell
instance (Function a, CoArbitrary a, Arbitrary b) => Arbitrary (Fun a b) where
  arbitrary =
    do p <- arbitrary
       d <- arbitrary
       return (mkFun p d)

  shrink (Fun (p, d, s) f) =
    [ mkFun p' d' | (p', d') <- shrink (p, d) ] ++ [ Fun (p, d, Shrunk) f | s == NotShrunk ]
```

Inside `arbitrary`,
we compute `p` and `d` by calling `arbitrary` twice.
`p` creates a value `Gen (a :-> b)`, or `Gen (String :-> Integer)`.
`d` creates a value `Gen Integer`.

Then, we create a result `Gen (Fun String Integer)` using `mkFun`.

`shrink` can be written also as:

```haskell
  shrink (Fun (p, d, s) f) =
    [ Fun (p', d', NotShrunk) (abstract p' d') | (p', d') <- shrink (p, d) ]
    ++
    [ Fun (p, d, Shrunk) f | s == NotShrunk ]
```

In deconstructs a given instance of `Fun` into:

* `p`, generated `a :-> b` instance
* `d`, generated `b` instance
* `s`, `Shrunk`/`NotShrunk` value,
* `f`, generated function `a -> b`

To shrink an instance, QuickCheck creates two lists,
one for `NotShrunk` instances,
that is instances that can be shrunk further and one for `Shrunk` instances.

The second list is a singleton list. It contains the value
we want to shrink as-is
but with `Shrunk` instead of `NotShrunk` as a third argument.

To create the first list, the function shrinks the pair `(p, d)`.
This returns a list of pairs, each containing a simplified function structure `a :-> b`
and a simpler value for the result type `b`.
The library then shrinks each pair and creates a `Fun`
from each result of pair-shrinking.

For shrinking the pair `(p', d')`, QuickCheck first shrinks `p'`,
gets a list of `a :-> b`,
and creates a list where each of these shrunk structures is paired with the original `d'`.
Then it does the same for `d'`. It creates an array of shrunk values
then it pairs each of them with the original value of `p'`.

Shrinking functions structures is all about inserting `Nil`
in the middle of recursive structures to create smaller trees.

To shrink a `:+:` value:

```haskell
shrinkFun shr (p :+: q) =
  [ p .+. Nil | not (q == Nil) ] ++
  [ Nil .+. q | not (p == Nil) ] ++
  [ p  .+. q' | q' <- shrinkFun shr q ] ++
  [ p' .+. q  | p' <- shrinkFun shr p ]
 where
  Nil .+. Nil = Nil
  p   .+. q   = p :+: q
```

For a value that can be either `p` or `q`, it generates many shrunk values.
One with `p` and `Nil`, one with `Nil` and `q`, some with the initial `p`
and with different shrunk values of `q`, and some with shrunk values of `q`
and with the initial value of `q`.

For `Unit`:

```haskell
shrinkFun shr (Unit c) = [ Nil ] ++ [ Unit c' | c' <- shr c ]
```

The result is an array of `Unit` values where each returns a shrunk value of the initial
returned value.

## Targeted testing with PropEr

PropEr follows the same logic for both normal and targeted testing.
It generates, tests, shrinks, and loops.
The abstractions are solid.
The inputs and the outputs of each step are the same.
The way PropEr represents types, generators, and shrinkers is
good enough to model both scenarios seamlessly.

During normal testing, the library generates instances of candidates for testing randomly.
It checks the property with big numbers, small and very small integers, and then big again, ...
During targeted Property-Based Testing, it follows a generation strategy.
A set of rules pushes the values toward greater chances of finding failed instances.

### The philosophy of targeted testing

The main components of targeted testing are the state and the target.

The state describes where we are: the current step, the size of steps
when updating the state, and the current temperature value.
The temperature is a value between `0` and `1`.
The number of steps is a value between `0` and the maximum number, which is `1000` by default.
As the number of steps grows, the temperature approaches `0`.

The target contains the generated instances. It orients the next generations.

To generate an integer, for example, we call:

```erlang
make_inrange(LastGeneratedValue, Offset, Min, Max)
```

The next integer will either be `LastGeneratedValue + Offset`
or `LastGeneratedValue - Offset`, as long as the result is in the range `Min..Max`.
`Offset` is a function of the temperature.
`Min` and `Max` are stored inside the integer type definition. We can override them.

The library provides a function to create `Offset` from a temperature, a scaling function.
It maps a number between `0` and `1` to an offset we can add or subtract from a generated value.
We can also define our scaling function.

The temperature, and thus the offset, changes when the fitness changes.
We move the temperature to `0` by updating the fitness.
If we provide a valid value for the fitness, the temperature is updated.
We can think of fitness as the value we use to move the temperature.

Whether a given fitness is valid or not depends on the strategy.
For hill-climbing, a value is valid if it's bigger than the last value
we used for the update.
This is why, in the implementation of `MAXIMAZE` update, the fitness value is the last
generated value.

Generation is managed by a neighborhood function instead of a generator.
Such a function calls the raw type generator internally.
However, it takes into consideration the last generated value
and the current temperature when returning an instance.

To shrink a value during targeted testing, we either shrink it
using the normal-testing shrinker, or we provide generators
that might also take the last generated value into account.

Targeted testing can be done with one or multiple workers.
Multiple workers need communication.
They need to synchronize the generation of instances so that each
generation, from whichever worker, pushes the values toward a target.
Such communication is performed with a server component, a shared worker
that generates the values for all the testing workers.

### A bridge between normal testing and a search strategy

Targeted testing is managed by a module named `proper_target`.
This module implements a
[`gen_server`](https://www.erlang.org/doc/design_principles/gen_server_concepts).

> This behavior module provides the server of a client-server relation.
> A generic server process (gen_server) implemented using this module has
> a standard set of interface functions and includes functionality for
> tracing and error reporting. It also fits into an OTP supervision tree.
> For more information, see section gen_server Behaviour in OTP Design Principles.

As opposed to a normal worker, which acts as a peer in a distributed network,
the target testing module acts as a server in a client/server architecture.
It manages the access to a shared resource.

If we perform testing with one worker, we won't need it to be a server.
A worker with a local state or a module with stateless functions that take the state
as arguments will be enough.

The server encapsulates the current state of generation.
It maintains:

* a structure named `target` that contains the current generation state
* a structure named `data` that encapsulates some variables that guide the generation
  and a reference toward a strategy module.

`data` is initialized to:

```erlang
#sa_data{k_max = Steps, p = get_acceptance_function(), temp_func = get_temperature_function()}
```

`k_max` is the maximum step count. It's `1000` by default.
Each temperature update is a new step. Steps after the maximum one are ignored.

The acceptance function is returned by `get_acceptance_function()` and it's kept inside `p`.
Such a function checks whether a new state (a new value of `Fitness` and `Temperature`) can build the next state or not.
The temperature function, returned by `get_temperature_function()`,
calculates the next temperature value.
We'll get back to these functions at the end.

`target` is initialized to:

```erlang
{ok, InitialValue} = proper_gen:safe_generate(First),
#sa_target{first = First, next = Next, last_generated = InitialValue}
```

`first` is the input type of the property. This is the type before wrapping.
`last_generated` contains the last generated instance.
It's initiated to a generated instance `InitialValue`.

`next` contains the function that'll generate the next instance.
It takes the last generated instance and the current temperature
and returns a new instance.
The last generated value orients the testing.

The targeted testing server acts as a bridge between normal testing logic
and a search strategy.
`quickcheck()` takes a search strategy as an option.
It can be a reference to a module or an atom describing a primitive strategy.
The default value is `proper_sa`.
It denotes an internal module that implements Simulated Annealing.

Each message the server gets is a request for a value.
It has an equivalent function in the strategy module.
To respond to a request, the targeted testing module calls a function from the strategy
module, passes the current state, and expects a return value and an updated state back.
It returns the value and updates the local state.

### Targeted generation

Before generating a new instance, PropEr wraps the initial input type using:

```erlang
Target = proper_target:targeted(RawType),
```

Generation itself is similar during both normal and targeted testing.
There's always an input type that's passed to `proper_gen:safe_generate`
which generates an instance that PropEr uses to check the proprety.
During normal testing, this is the type of the property input.
We'll call it the "raw type".
During targeted testing, it's a custom type that wraps the raw type.
We'll call it the "wrapper type".

This custom type delegates both generation and shrinking to the targeted
testing server.
Its generator looks like this:

```erlang
TargetserverPid = get('$targetserver_pid'),
gen_server:call(TargetserverPid, gen)
```

The library sends a message `gen` to the targeted
testing module and returns the response.
`$targetserver_pid` is the pid of the server.

In the handler of a `gen` message, the targeted testing module
uses the `next` function from the `target` structure to generate
an instance.

This `next` function is created before the testing starts.
To create it, the module looks for a replacer generator that works
with the property raw type inside the list of generators it maintains.
A "replacer generator", or a "neighborhood function",
is the generator of the wrapper type.

The replacer generator of integers looks like this:

```erlang
#{max := MaxD} = get(?GEN_NEXT_DEPTH),
Temp = if
          MaxD =:= 1 -> Temperature;
          true       -> 0.25 + 0.25 * 1/(1-MaxD) * Temperature * (Depth-1);
       end,
OffsetLimit = trunc(abs(Min - Max) * Temp * 0.1) + 1,
Offset = proper_arith:rand_int(-OffsetLimit, OffsetLimit),
make_inrange(Base, Offset, Min, Max)
```

This code fetches the values of `Min` and `Max` from the raw type structure,
finds an offset, and then pushes the last generated value up or down within the offset range.

`make_inrange` takes a value, an offset, and a range.
It returns either `value + offset` when value `value + offset` stays inside the range.
It returns `value - offset` when `value + offset` falls outside.
And if any of these additions falls outside the range,
the lower or the higher bound of the range is returned.

`Offset` is a random number between `-OffsetLimit` and `OffsetLimit`.
`OffsetLimit` grows as `Temp` gets bigger. That is, as we make more steps.

`Temperature` in the second line is `Data#sa_data.temperature`.
It's the current temperature in the server state.

`Depth` is the order of the current replacer generator in the recursive generation.
A replacer generator might call other replacer generators.
For example, to generate a list of integers, its replacer generator
calls the integer replacer to generate each element.
`Depth` is initially `1`. It can incremented before the list generator generates a new element in the list.
And, it's always incremented at the beginning of the inner type replacer generator.

`GEN_NEXT_DEPTH` is a macro that evaluates to the atom `proper_gen_next_cache_depth`.
It's defined as:

```erlang
-define(GEN_NEXT_DEPTH,  proper_gen_next_cache_depth).
```

The macro is a shorthand for the whole atom name.
This reduces the probability of conflicts
because the name is big and because it's stored inside the process dictionary.

`GEN_NEXT_DEPTH` is initialized to `1`.
`Temp` will be the value of `Temperature` for the first generation.
It's incremented if we adjust the temperature by calling `adjust_temperature`.
The latter is often called when a replacer generator uses a replacer generator of another type.
To create a list of integers, the replacer generator of a list increases
`GEN_NEXT_DEPTH` and calls the replacer generator of an integer to generate
an element.

Each replacer generator creates a new type, we'll call it the "replacer type".
To sum up, the generator inside the "wrapper type" uses the current temperature
and the last instance to create a "replacer type".
The replacer generates an instance of this latter using `proper_gen:safe_generate`.
The returned value is used to check the property.

The creation of a replacer type is done in two steps,
one at the beginning during initialization
and one during the generation of an instance.

The first looks like this:

```erlang
{ok, Replacer} = get_replacer(InitialType),
UnrestrictedGenerator = Replacer(InitialType),
RestrictedGenerator = apply_constraints(UnrestrictedGenerator, InitialType),
TemperaturedGenerator = apply_temperature_scaling(RestrictedGenerator),
```

`Replacer` is the replacer selected from the maintained list.
`UnrestrictedGenerator` is the generator that takes an instance
and a temperature and returns a new instance.

`apply_constraints` makes sure the generated instance satisfies the constraints of the raw type.
It creates a function that executes the replacer generator.
If the value returned by this generator does not satisfy all the constraints.
It tries to execute it again and get a new value.
If it does satisfy, it returns it.

`apply_temperature_scaling` takes the generator and generates a new one itself.
The new generator calls `RestrictedGenerator` with an incremented depth if this
generation is not the root generation. It sets the depth to `1` otherwise.

The second step looks like this:

```erlang
BaseType = new_type({ generator, () -> TemperaturedGenerator(Base, Temperature) }, wrapper),
{ok, Parameters} = proper_types:find_prop(parameters, InitialType),
Type = proper_types:with_parameters(Parameters, BaseType)
```

`Base` is the last generated value.
`Temperature` is the current temperature.
`Type` is the replacer type.
`TemperaturedGenerator` is the generator created in the first step.

### Targeted shrinking

The "wrapper type" is created as:

```erlang
?SHRINK(
  proper_types:exactly(?LAZY(targeted_gen())),
  [get_shrinker(Type)]
)
```

The first argument of `?SHRINK` is the "wrapper type".
The second argument is the list of shrinkers we'll include in this type.
That list contains only `get_shrinker(Type)` here.

Here are some examples from shrinking tests:

```erlang
{?SHRINK(pos_integer(),[0]), ...},
{?SHRINK(float(),[integer(),atom()]), ...},
```

The second argument of `?SHRINK` is the list of alternative generators.

```erlang
%%%   ...the generators in `<List_of_alt_gens>' are first run to produce
%%%   hopefully simpler instances of the type. Thus, the generators in the
%%%   second argument should be simpler than the default. The simplest ones
%%%   should be at the front of the list, since those are the generators
%%%   preferred by the shrinking subsystem. Like the main `<Generator>', the
%%%   alternatives may also evaluate to a type, which is generated recursively.
```

`get_shrinker` is the response of sending the message `shrinker`
to the targeted testing module:

```erlang
TargetserverPid = get('$targetserver_pid'),
gen_server:call(TargetserverPid, shrinker)
```

The handler of this message returns either the raw type of the property
or a new type created by evaluating `user_nf` property.
`user_nf` is an option we can pass initially to `quickcheck()` if we want
to override the default replacer generator/neighborhood function.

For example, when the user neighborhood function is:

```erlang
?USERNF(exactly(0), fun (Base, _) -> Base + 1 end)
```

The first generated instance will be `0`, the next will be `1`, and so on.
Each newly generated instance is an incremented value of the previous one.

Here is another occurrence of the "delay" pattern. The alternative types
are created when shrinking. They're selected at the moment
of creating the "wrapper type".
For this operation to handle the list similarly, the alternative generator is encapsulated as the return of a function.

This macro is used:

```erlang
-define(DELAY(X), fun() -> X end).
```

Another way to implement this is to create an aggregator.
We put each value inside the moment it's ready.

The type returned by `get_shrinker` is not used directly during shrinking.

The "wrapper type" shrinkers are `unwrap_shrinker` and `alternate_shrinker`.
They unwrap the "wrapper type", get a list of types,
then look for the type of the target instance in this list.
The alternative generator is the first element in the list.
They are followed by the raw type of the property.

The type both shrinkers look for is called the "plausible type".
It splits the list of types in two.

`unwrap_shrinker` follows the same shrinking approach as normal testing.
The "plausible type" is a type structure that contains some shrinkers,
usually simple shrinkers.
`unwrap_shrinker` uses them to simplify the failing instance.

`alternate_shrinker` generates values using the generators of the "plausible type"
and the types that preceded it in the list of types generator.
Each generated instance of these types is a candidate shrinking
value of the wrapped type.

### Manually pushing the values up

```erlang
prop_int() ->
  ?FORALL_TARGETED(
    I,
    int_user_nf(),
    (I) ->
      ?MAXIMIZE(I),
      I < 500
  ).
```

`?MAXIMIZE` is called at the beginning of the body to push the generated values of `I` up.
It sends a message `update_fitness()` to the targeted testing server.
All interactions with targeted testing go through a message to the server.
The handler calls `update_fitness()`
to update the structure that contains the temperature and the fitness:

```erlang
{ NewTarget, NewData } = Strategy:update_fitness(Fitness, Target, Data),
```

`Target` is the existing target structure.
`Data` is the existing data structure.
`Fitness` is the body of the message `update_fitness`.
This value is set by the test author when he calls `MAXIMIZE`
or `MINIMIZE` in the test body.

A test where we change the fitness might also look like this:

```erlang
prop_target() ->                 % Try to check that
  ?EXISTS(Input, Params,         % some input exists
          begin                  % that fulfills the property.
            UV = SUT:run(Input), % Do so by running SUT with Input
            ?MAXIMIZE(UV),       % and maximize its Utility Value
            UV < Threshold       % up to some Threshold.
          end).
```

Here, `Fitness` is the value of `UV`.

`update_fitness` checks whether a state with this new fitness value is valid or not
using the acceptance function.
If the state is valid or during the first call to `update_fitness`,
it creates a new temperature with the temperature function
and updates the last generated value, the temperature, and the current step.
If it's not, it creates a new temperature with the temperature function
and updates the temperature and the current step.

The acceptance function differs depending on the search strategy.
During hill-climbing, it returns `true` when the new fitness value
is bigger than the old. Otherwise, it returns `false`.
During simulated annealing, it returns `true` when the new fitness
value is bigger or when the probabilistic acceptance is bigger than a random probability threshold.

The random probabilistic value is a fixed value generated initially
(`rand:uniform()`)[https://www.erlang.org/doc/man/rand#uniform-0].
The acceptance value is:

```erlang
1 / (1 + math:exp(abs(EnergyCurrent - EnergyNew) / Temperature))
```

The default temperature function, that is the one that'll be used if no such function is
set explicitly, handles both accepted and rejected states similarly.
It moves the temperature to 0 as the current step gets bigger,
and it increments the current step by 1:

```erlang
{1.0 - min(1, K_Current / K_Max), K_Current + 1}.
```

`K_Current` is the current step.
`K_MAX` is the number of search steps.

## PropErp type server

Types in PropEr are structures.
Due to the good meta-programming support, they can be passed also as strings.

```erlang
%%% PropEr can parse types expressed in Erlang's type language and convert them
%%% to its own type format. Such expressions can be used instead of regular type
%%% constructors in the second argument of `?FORALL's.
```

The module implements a server as multiple testing workers can parse spec tests.
Spec tests are signature-based properties.
The signature of spec is parsed as a `String`.
It's then transformed into type structures by this module.

At the core, creating a spec test is:

```erlang
Test = ?FORALL(
  Args,
  FinType,
  apply_spec_test(MFA, FunRepr, SpecTimeout, FalsePositiveMFAs, Args)
)
```

* `FinType` is the result of converting the input type of the property to a PropEr type structure.
* `MFA` is a structure that contains the module, the name, and the arity of the spec to test.
* `FunRepr` is the entry inside the state `exp_specs` that parses the target spec.
* `SpecTimeout` is a timeout that ensures the spec execution time is bounded.
* `FalsePositiveMFAs` is a function that's called with the result of the spec.
  The returned value of the function that implements the spec might have a different type than the spec return type.
  If such a value is tested and marked valid by `FalsePositiveMFAs`, the check succeeds.

`apply_spec_test` uses `?DELAY` to create a function that takes no arguments and that evaluates
`apply(Mod, Fun, Args)`.
The created function returns `true` when the type of the outcome of this application is the same as
spec return type, or when `FalsePositiveMFAs` considers it valid if it has a different type.

The type server starts before checking a property and stops at the end.
It maintains a state that contains the translated/parsed types, named `cached`.
It's a dictionary where the key is the raw type and the value is the final type.
Given a type to translate, the module checks the cache first.

The state contains another dictionary for modules, named `exp_types`.
The keys are module names. The values are references to the types inside the modules.
Each type reference is composed of a type name (an atom) and an arity value.
The intersection of module/name/arity identifies a type.

Erlang offers meta-programming utilities such as the functions inside `erl_scan` and `erl_parse`.
[erl_scan:string](https://www.erlang.org/doc/man/erl_scan#string-1)
takes a string and tokenizes it.
[erl_parse:parse_form](https://www.erlang.org/doc/man/erl_parse#parse_form-1)
transforms the tokens into an abstract syntax tree.

The given string might be a valid expression but still not a type.
`parse_type` tokenizes then parses a fake type definition created with the type:

```erlang
"-type mytype() :: " ++ GivenString ++ "."
```

It deconstructs the AST tree returned by this and extracts the type expression.

The core logic of translating a string describing a type is:

```erlang
{Mod,Str} = ImmType,
{ok,TypeForm} = parse_type(Str),
{ok,NewState} = add_module(Mod, State),
{ok,FinType, #state{cached = Cached} = FinalState} = convert(Mod, TypeForm, NewState),
```

`add_module` checks whether the module exists in the current state of the server.
That is, if there's an element in the dictionary `exp_types` for it.

If not, `add_module` parses the module. It saves its exported types and spec tests to its state.
Using the same utilities used to parse a type, the library parses the module source code
and searches for exported expressions.

It iterates over the abstract code using a `foldl` operator.
It tries to match each element with one of the expected structures.

An exported type is detected using the first atom `attribute`:

```erlang
{attribute,_Line,export_type,TypesList}
```

Here `TypesList` is added to the list of exported types inside the state.

A spec has the atom `spec` as a third argument:

```erlang
{attribute,_Line,spec,{RawFunRef,[RawFirstClause | _Rest]}}
```

The function name and its arity are extracted from `RawFunRef`.
Its range and domain are extracted from `RawFunRef`.
Then a new entry is added to the dictionary of specs where the
key is the pair `{Name,Arity}` and the value is the pair `{Domain,Range}`.

`convert` computes the updated state and the final type structure.
The letter is a structure we can use to generate instances for a property using `proper_gen:safe_generate()`.
The type server deconstructs the AST node `TypeForm`.
Depending on the atom that represents the type name,
it uses the same constructs the main module uses to define types.

If the given type is a list of integers, the server expects `TypeForm` to be:

```erlang
{type,_,list,[ElemForm]}
```

and `ElemFrom` to be:

```erlang
{integer,_,_Int}
```

To create a type structure, it uses:

```erlang
proper_types:list(proper_types:exactly(Int))
```

which is inlined to:

```erlang
new_type(
  [
    {generator, {typed, fun list_gen/2}},
    {is_instance, {typed, fun list_is_instance/2}},
    {
      internal_type,
      new_type([{env, Int}, {generator, {typed, fun exactly_gen/1}}], basic)
    },
  ],
  container
)
```
