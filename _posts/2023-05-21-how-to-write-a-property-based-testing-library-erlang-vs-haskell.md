---
layout:   post
comments: true
title:    "How to write a property based testing library: Erlang vs Haskell"
date:     2023-05-21 12:02:00 +0100
tags:     featured
---

[Property-based testing](https://en.wikipedia.org/wiki/Software_testing#Property_testing)
is a test automation approach that checks invariants instead of concrete examples.
When a test subject (a component or a function for example) has a huge input space
(it takes strings, real numbers, combinations of parameters, ...),
making sure the code returns a valid result no matter which
composition of inputs we pass requires many example-based tests.
Testing every combination of parameters, or every conceivable string, will take forever.
The drawback of writing and maintaining these tests outweighs
the benefit of having them in the first place.

Writing property-based tests increases our confidence in the code without that
a significant cost.
Testing a sort function is a classic use case.
We define a property that compares the sum of the result array elements
to the sum of the initial array elements.
If they're different, the function needs some work.

A property-based testing library builds different shapes of arrays:
an empty array, arrays with one element, arrays with huge numbers of elements,
with duplicated elements, with negative numbers, ...
It checks the property for each of generated values.
If any of them fails the property, the library tries to squeeze it
or to "shrink" it if we are to use the right term.
It returns the simplest possible counterexample.

It's interesting to see how different languages implement such a library.
Both [Haskell](https://en.wikipedia.org/wiki/Haskell)
and [Erlang](https://en.wikipedia.org/wiki/Erlang_(programming_language))
are functional programming languages.
They embrace ideas like purity and immutability.
But they approach the model differently.
Haskell is typed.
Erlang is not.
Haskell has native support for group theory constructs.
Erlang is message-based.
Haskell embraces lazy evaluation.
Erlang provides primitive constructs for concurrent execution
and a fault-tolerant platform.
Haskell has lazy evaluation by default.
And so goes the contrast.


## QuickCheck
[Quickchek](https://github.com/nick8325/quickcheck) is a Haskell property-based testing library.

Let's say we have a function `reverse` that reverses an array of integers.
We can define a property `prop_reverse` that takes an array,
reverses it twice, and compares it to the original array.

```haskell
prop_reverse inputArray = (reverse (reverse inputArray)) == inputArray
```

We call `quickCheck` to run the test:
```haskell
>>> quickCheck (withMaxSuccess 10000 prop_reverse)
+++ OK, passed 10000 tests.
```

A property is a function that returns a boolean value or a result structure.
Returning a structure provides more context to the code that checks the outcome.
Other than the boolean result of passes/fails,
a such structure contains an attribute `expect` whose value is also boolean.
When it's true and the property succeeds, the testing fails.
That is, when it's true, the property should return `False` for the testing
to continue.

`quickCheck` needs a property and a set of testing parameters to start its engine.
This engine is a loop.
In each iteration, it builds an input candidate, uses it to check the property,
then decides whether:
  * to stop testing and fail
  * to stop testing and succeed
  * to continue testing (to run another iteration: to generate another input, and to check it)

This engine is managed by a function named `test`,
defined as
```haskell
test :: State -> Property -> IO Result
```

It takes a state `State` and a property `Property`,
and decides whether to finish testing or to test the property again.
Internally, it tests the property. It creates a new state.
Then, it calls itself recursively until the testing stops.

### Result
We'll go through the types of `test`.
Each iteration of the engine returns a `Result` variable.
The value returned by the last iteration is
the one returned by the engine at the end of testing.

This value is a structure defined as:
```haskell
data Result
  = Success { ... }
  | GaveUp { ... }
  | Failure
    { ...
    , reason          :: String
    , failingTestCase :: [String]
    }
  | NoExpectedFailure { ...  }
```

It's:
 * `Success` after a successful iteration.
 * `GaveUp` after reaching a threshold of discarded tests.
    A test is discarded when an error occurs,
    like a failure to generate an input or an exception during the execution of the property.
 * `Failure` after a failed iteration.
    Two important attributes inside this variant are the failure reason and the simplest counterexamples.
 * `NoExpectedFailure` when the property should have failed, but did not.

 An example of a property that should fail is:
 ```haskell
our_prop n = expectFailure (n === n + 1)
```

Here we're comparing an integer `n` to `n + 1` and we're encapsulating
the result with `expectFailure` inside a result structure.

Here's how PropEr converts the structure returned by the property
into a `Result` value.
It checks the `ok` attribute, which contains the outcome of the test.
Then, it checks `expect` attribute.

```haskell
case res of
  MkResult{ok = Just True} -> -- successful test
    return Success{ ... }

  MkResult{ok = Just False} -> -- failed test
    ...
    if not (expect res) then
      return Success{ ... }
    else do
      return Failure{ ... }
```

### State
Haskell functions are pure.
Each iteration builds a state and passes it to the next iteration.
A state is a data structure that reifies the progress.

It contains
the number of tests done, the number of successful tests,
the number of required iterations, a reference to a terminal to notify the
users about the testing progress, ...

If you want to write your own library, put here what the global values you need
and update them after each iteration.

### Property and Testable
Properties can be built from functions or propositions.
`prop_reverse` above is a function.
`cyclicList_prop` here is a proposition:
```haskell
cyclicList_prop = forAll cyclicList $ \(xs) -> and $ zipWith (==) xs (drop 2 xs)
```

`cyclicList_prop` checks whether a generator, `cyclicList`,
produces arrays with period `2`.
Each array should repeat two integers `n` times.

`Property` type is defined as:
```haskell
newtype Property = MkProperty { unProperty :: Gen Prop }
```

We can think of a `Property` as a bridge between a `Testable` instance
and a property generator `Gen Prop`.

A property generator is a moderator of an iteration.
It references an array generator (or an input generator in general)
and the checking function.
It generates a value, checks it on the property, and creates a `Result`.

`Testable` is a class of values that QuickCheck knows how to transform into
a `Property` or a `Result`.
That's why functions and propositions are `Testable` instances.

### The heartbeat of the engine
The key to understanding how QuickCheck works is to understand how it
builds a `Property` value from a given function or proposition.

Because, once we have a property, we evaluate this expression and get a `Result`:
```haskell
(unProp (unGen (unProperty our_property) rnd1 size))
```

This expression returns to a `Rose Result` value, which encapsulates a result.
And, it's a mere unfolding of folded values.
First, we call `unProperty` on a `Property` instance, `our_property`.
We unfold the result with `unGen`, get a `Prop` value,
unfold this too with `unProp`, and get a `Rose Result`.

Folding is unfolding.
So let's see how `our_property` is created.

### Gen
As shown in the definition `Property`,
we can create a property if we have a `Gen Prop` value, a property generator.
```haskell
our_property = MkProperty our_gen_prop_value
```

or to take the code from QuickCheck itself:
```haskell
MkProperty $
  gen >>= \x ->
    unProperty $
    shrinking shrinker x pf
``` 

`Gen` is defined as:
```haskell
newtype Gen a = MkGen{
  unGen :: QCGen -> Int -> a -- ^ Run the generator on a particular seed.
}
```

This is the definition of a generator is QuickCheck.
If `a` is `Prop`, we have a property generator.
If `a` is `Int`, we have an integer generator.
If `a` is a custom type `User`, we have a user generator.

We create a generator by providing an `unGen` function,

```haskell
our_generator = MkGen our_unGen_function
```

`unGen` takes a random number generator `QCGen` and a size integer.
Both are defined in the state passed between the iterations.
The size value prescribes to generators how complicated the instances should be:
how deep the tree goes, how long the array stretches,
and inside which interval a randomly generated number can be.
Its default value is `30`, and it's set inside the options we pass to `quickCheck`.

The library defines generators for basic types like `Int`, `Boolean`, `Char`, ...
It can also build generators for the types that can be constructed
(array, sum, and product types).
If we want a custom generator, we can define one as well.

### Arbitrary
To generate a value of type `a`, we need a generator instance, `Gen a`.
We can create a generator by calling `arbitrary`.

QuickCheck defines a class `Arbitrary` with two functions:
 * `arbitrary :: Gen a` to generate input values
 * `shrink :: a -> [a]` to shrink a value

 It implements this class for common types.

 For example, we can have an implementation for integers:
 ```haskell
 instance Arbitrary Int where
  arbitrary =  MkGen (\randomGen size -> randomR (-size, size) randomGen)
  shrink    = \x -> [(abs x) - 1]
 ```

For composite and custom-defined types, we can define our generators and our shrinking
in the same way.

The documentation says
```haskell
-- There is no generic @arbitrary@ implementation included because we don't
-- know how to make a high-quality one. If you want one, consider using the
-- <http://hackage.haskell.org/package/testing-feat testing-feat> or
-- <http://hackage.haskell.org/package/generic-random generic-random> packages.
--
-- The <http://www.cse.chalmers.se/~rjmh/QuickCheck/manual.html QuickCheck manual>
-- goes into detail on how to write good generators. Make sure to look at it,
-- especially if your type is recursive!
```

### Property generators
We create a property generator `Gen Prop` instance by defining an `unGen` function.

QuickCheck creates a property generator `Gen Prop` if we give it an input generator.
In `prop_reverse`, QuickCheck has already an `Int` generator and an array generator.
In `cyclicList_prop`, we define an input generator `cyclicList`.

Let's say `gen` is our `Gen [Int]` generator. `f` is a property,
a function whose signature is:
```haskell
[Int] -> Bool
```

We create a property generator from an input generator as:
```haskell
gen >>= \x -> unProperty $ shrinking shrinker x f
```

This defines a property generator whose `unGen` function uses `gen` to generate `x`.
Then, it calls `shrinking` and passes it to `unProperty`.

As specified in the definition of `Property`, `unProperty` returns `Gen Prop`.

`x` is the generated input that we use to check the property.
But, we're not calling `f x` directly.
We're starting a shrinking process instead.

`shriking` calls `f x` internally.
If the result is `True`, it returns it.
If the result is false, it starts a shrinking process to simplify `x`.

To be more specific, `shriking` returns a `Property` value.
That is, it returns a value that encapsulates a property generator `Gen Prop`.
We extract this last by calling `unProperty`.

In other words, the property generator is created by `shrinking`.

### Shrinking
`shrikning` function gets a `shrinker`.
This shrinker is the one from the `Arbitrary` class,
the shrinker of the input type.

`shrinking` builds a [rose tree](https://en.wikipedia.org/wiki/Rose_tree).
The root node contains the result of applying `f` to `x`, the originally generated value.
The children contain the results of applying `f` to shrunk values of `x`.
The grandchildren are the results of applying `f` to the shrunk values of the shrunk values of the original value.
And, so it goes.
The building stops when a shanked element passes the property.
That is when `f shrunk_value` returns either `True` or a successful result.

If the result of the property is a boolean value,
QuickCheck transforms it into a `Result` value,
either `MkResult{ok = Just True}`
or `MkResult{ok = Just False}`.

And as `Result` is a `Testable` instance, we get a tree of `Testable` instances.

The library knows how to transform a `Testable` instance into a `Property`.
So it transforms the tree.
Node by node, each value becomes a `Property`.
But, these "properties" are different.
They're not created with the expression we use to create the main `Property`.
They're shadow properties or null properties.

Calling `unProperty` on each of them returns a null generator,
a generator whose `unGen` is a constant function.
No matter which inputs (random number generator and size) we pass in,
it always returns the same `Prop` value.

`Prop` is defined as:
```haskell
newtype Prop = MkProp{ unProp :: Rose Result }
```
It encapsulates a `Rose Result` value.
Our null property encapsulates
a single-node rose tree that contains the `Result`
value of that node.
Calling `unProp` on such `Prop` always returns this single-node rose tree,
whose type is`Rose Result` value of the node,

That said,
calling `unGen` on each element gives a tree of `Gen Prop`.
The type of tree will be `Rose (Gen Prop)`.
QuickCheck transforms this into `Gen (Rose Prop)`.
The transformation is simple because generators are constants.

All that the library needs to do is to create a rose tree with the single-nodes containing the `Prop` values,
then to encapsulates it inside a generator whose `unGen` always returns this same tree.
This, too, is a null generator.

And same, we call `unProp` on each `Prop` element inside the tree `Rose Prop`
and get a tree of `Rose Result`.
The type of this tree is `Rose (Rose Result)`.
This is a tree where each element is a single-node tree that contains
the result of applying the property to the shunk elements.

### Rose Result
`Rose` is defined as `Rose = MkRose a [Rose a]`.
The tree `Rose (Rose Result)` we get, is a flat structure.
It's an array built following a
[depth-first traversal](https://en.wikipedia.org/wiki/Tree_traversal#Depth-first_search)
of the tree.

With a rose tree `Rose (Rose Result)`.
QuickCheck uses a function `joinRose` to transform it into a `Rose Result` value.
That is:
```erlang
joinRose (MkRose (MkRose x ts) tts) =  MkRose x (map joinRose tts ++ ts)
```

We get a structure that looks like this:
```haskell
our_result =
  MkRose (MkResult{ ok = Just False }) [
    MkRose (MkResult{ ok = Just False, P.reason = "whatever..." }) [
      MkRose (MkResult{ ok = Just True }) []
    ],
    MkRose (MkResult{ ok = Just True }) [],
  ]
```

From this, the result of the iteration will be:
```haskell
MkResult{ ok = Just False, P.reason = "whatever..." }
```

It's the job of `shrinking` function we introduced above to get us this value.
Indeed, `shrinking` returns a `Property` whose `Gen Prop` is a constant.
Calling `unGen` on it returns a `Prop`, which also is a constant.
Calling `unProp` on it returns a `Rose Result`,
which is a single-value tree that contains the result.
With this returned result, the engine decides whether to start a new iteration
or end the testing.

`shrinking` iterates over the children and tests them to find
the simplest value that fails the property.
In each level, if the property succeeds, it checks the adjacent nodes/elements.
If it fails, it goes on checking the children nodes/elements.
It stops when a threshold of attempts is reached or after testing all the results available.

If we take the expression from the fourth section above and try to understand it now:
```haskell
(unProp (unGen (unProperty our_property) rnd1 size))
```

`our_property` is the `Property` created by `shrinking`.
`unProperty our_property` is the property generator created by `shrinking`.
By calling `unGen (unProperty our_property) rnd1 size`:
  * a tree is built, transformed, simplified, and reduced to one node
  * a null generator that always returns a `Prop` that encapsulates this tree is created and returned.

As a null generator is returned,
calling this `unGen` expression returns the result of `unGen` on the null generator.
This is how monads work.

By calling `unProp`, we get `Rose Result`.
We deconstruct it and get the final `Result`.

### Do we really create a tree?
Tree creation is a good example of lazy evaluation in Haskell.
QuickCheck does not build the tree at all.
Neither the tree of `Testable` elements nor that of `Gen Prop` elements,
and neither that of `Rose Result` elements.

It just pretends to create them.
When we want to see what's inside a node, only then Haskell builds a node.
That is, only then it creates a `Testable` instance,
a `Gen Prop` instance,
and a `Rose Result` instance when we access a node/element.
It does not create children though.
It does that when we read them.

If we have to do a maximum of `100` shrinks, Haskell builds `100` nodes,
even when the code says it's building a tree with thousands of elements.

## PropEr
[`PropEr`](https://github.com/proper-testing/proper) is the common Erlang
property-based testing library.

We call `quickheck` to test a property:
```erlang
prop_enc_dec() ->
  ?FORALL(
    Msg,
    union([binary(), lists:seq(1, 255)]),
    base64_decode(base64_encode(Msg)) =:= Msg
  ).

quickcheck(prop_enc_dec(), [{numtests,10000}])
```

In this example, we're creating a property `prop_enc_dec` using `FORALL` macro.
The property checks whether a given `Msg` stays the same after
encoding and decoding it in base 64.

`union([binary(), lists:seq(1, 255)])` is the input type.
PropEr uses this definition to generate instances to pass into the function
in the third argument.
The input can be:
  * either a binary value, a list of randomly generated bytes (values between 0 and 255)
  * or an array that contains the sequence of numbers from 1 to 255. Erlang transforms
    this into a binary value by mapping each element into a byte.

### What's a property
Erlang has a good meta-programming system.
The library uses [macros](https://en.wikipedia.org/wiki/Macro_(computer_science)) heavily.

A property is a structure, or a tuple in Erlang terms.
`FORALL` macro above translates into this structure:
```erlang
{
  forall,
  union([binary(), lists:seq(1, 255)]),
  fun(Msg) -> base64_decode(base64_encode(Msg)) =:= Msg end
}.
```

The first element is an atom that guides the testing.
It's an atom.
An atom in Erlang is some kind of a symbol.
It's like a global value but it evaluates to itself.
It's its own value.
It can also be `exists`, `conjunction`, `timeout`, or `trapexit`.

When it's `forall`, the library generates an instance and tests it.
It should always pass.

`implies`, 
The first element can also be `exists`, `conjunction`,,or `timeout`.

When the it's `exists`, PropEr should follow a targeted search strategy.
I'll introduce it in the next post.

When it's `conjunction`, PropEr tests a generated instance on multiple properties.
The propery is succeful when all the sub-properties are successful.
Such property is in the form `{conjunction, SubProperties}`.
`Subproperties` is a list of properties.

When it's `timeout`, it spawns a new worker to execute the property
and it expects the result before a given timeout.
That is, the worker spawned to run the check should send a message with
a successful result before the time is out.

Here's how a simplified version of its implementation:
```erlang
Child = spawn_link_migrate(undefined, fun() -> child(self(), Prop, Ctx, Opts) end),
receive
  {result, RecvResult} -> RecvResult
    after Limit ->
        unlink(Child),
        exit(Child, kill),
        create_fail_result(Ctx, time_out)
    end;
```

`spawn_link_migrate` starts a worker to execute `child(self(), Prop, Ctx, Opts)`.

`child(...)` runs the property check and sends the result back to the father:
```erlang
child(Father, Prop, Ctx, Opts) ->
  Result = force(Prop, Ctx, Opts),
  Father ! {result,Result},
  ok.
```

`force` runs the test. We'll talk about it later.

`receive` waits for the spawned worker message.
`RecvResult` is the received message.
`create_fail_result` creates a failure result after a timeout.
`Limit` is the timeout value.

When the first element of the tuple is `trapexit`,
ProEr expects the property to throw uncaught exceptions or to emit an exit signal.
In both cases, Erlang worker terminates and sends an `EXIT` signal to its proviser.

The library first configures the system to transform such signal into an `EXIT` message.
It spawns a worker to execute the check and send the result back.
And, it waits for this result.

Such a property can be:
```erlang
?FORALL(X, pos_integer(), ?TRAPEXIT(creator(X) =:= ok))
```

`?TRAPEXIT` creates a tuple that starts with `trapexit`.

If we evaluates the macros, we get this structure:
```erlang
{
  forall,
  pos_integer(),
  fun(X) -> {trapexit, fun() -> creator(X) =:= ok end} end
}.
```

`creator` should emit an `EXIT` signal.
We can define it as:
```erlang
creator(X) ->
  spawn_link(fun() -> exit(this_is_the_end) end),
  receive
    _ -> ok
  end.
```

As in the property here, the checking function can return another property,
a structure like `{trapexit, ...}` in this example.
This allows us to create rich properties.
When a test structure is returned, a new testing sub-iteration starts.
This last may generate a new value depending on the initial instance,
it may use the initial instance,
or it may ignore the original generation and generates its own instance.

For example:
```erlang
{forall, integer(), (N) -> {forall, integer(), (M) -> N + diff(N, M) =:= M } }
```

The second element in the property tuple is the input type.
In our example, we're creating a type by joining a type, `binary()`, with a value, the sequence.
The concept of a type in PropEr is not the usual one.
A type in Erlang is a structure that contains generators, constraints, shrinkers, and other
attributes that guide testing.

The last element in the property tuple is the checking function.
The check takes a generated input and returns a boolean value or a result value like the
one we saw in the previous example.

### Sequential tests execution
`quickcheck` takes a list of options and a property.
In the example above, we pass in one option, `{numtests,10000}`.
It denotes the number of inputs ProEr will generate.
If all of them pass the test, testing stops and the property is successful.

Many other options are available.
PropEr will set default values for the options we don't specify explicity.

Another option is `numworkers`, the number of workers.

It
```erlang
Specifies the number of workers to spawn when performing the tests (defaults to 0).
Each worker gets their own share of the total number of tests to perform.
```

A worker in Elang is a construct quite similar to a green thread.
It's created to perform concurrent tasks in parallel.
Erlang core philosophy lies in the implementation of these workers.
They have a well-defined interface, they communicate through messages,
and they're managed by the [OTP](https://www.erlang.org/doc/design_principles/des_princ.html).
This virtual machine stops crashes from propagating through the system.
It restarts crashed workers and resend missed messages.
It transform unhandled exception into messages to parent processes.
But, it does not allow such errors to take down the application.

When the number of workers is `0`, the execution of tests is sequential.
One worker handles the work.
The logic is defined inside a function named `perform`.
This function calls itself recursively until it reaches the threshold of `numtests`,
or until a generated instance fails the property.

Each iteration generates an instance and tests it.
If the testing succeeds, a `#pass` structure is created, `#pass{}`.
If the input fails to pass the property, a `#fail` structure is created,
```erlang
#fail{reason = Reason, bound = lists:reverse(Bound)}
```

`Reason` is `false_prop` for simple properties.

`Bound` is the list of instances that failed the property.
It has one element when the checking function returns a boolean value.
It contains an instance for each sub-property that failed
when the checking function recursively returns properties.

### Generation
The second element of the property tuple is the type.

It's defined by:
```erlang
-opaque type() :: {'$type', [type_prop()]}.
```

Each `type_prop` in the second element list is a two-elements tuple.
An atom denoting name the attribute as a first element.
A value of the attribute as a second element.

Here's part of the definition of `type_prop`:
```erlang
-type type_prop() ::
      {'kind', type_kind()}
    | {'generator', proper_gen:generator()}
    | {'reverse_gen', proper_gen:reverse_gen()}
    | {'shrinkers', [proper_shrink:shrinker()]}
    | {'noshrink', boolean()}
    | {'combine', proper_gen:combine_fun()}
    | {'constraints', [{constraint_fun(), boolean()}]}
    | ...
```

The common attirbutes
are the generator, the list of shrinkers, and the list of constraints:
`generators`, `shrinkers`, and `constraints`.

PropEr puts generation logic inside a module named `proper_gen`.

Inside `perform`, PropEr runs:
```erlang
case proper_gen:safe_generate(RawType) of
  {ok, ImmInstance} ->
    Instance = proper_gen:clean_instance(ImmInstance),
  {error, Resaon} ->
    ...
```

`ImmInstance` is a generated value.
`Instance` is the value that the library passes to the checking function.
We call `clean_instance` because the generated values wraps the instance inside a context.

Usually, `Instance` is the same as `ImmInstance`.
But if the value is constructed, the generated value will be a tuple
containing the generated parts as well as the final value.

The type structure contains an attribute named `kind`, whose value can be:
```erlang
-type type_kind() :: 'basic' | 'wrapper' | 'constructed' | 'container' | atom().
```

It guides the generation.
A constructed type, one whose kind is `constructed`, should define `parts_type` and `combine` attributes.
To generate an instance of such type, the generated calls `generate` with the type of the parts
and get a list of instances back.
It calls `clean_instance` to remove their contexts.
Then, it calls the value of `combine` attribute which combines them into one value.
It returns this combined value and a context that contains the generated parts.

`proper_gen:safe_generate` calls `proper_gen:generate`.
The difference is that the `safe_generate` returns an `error` tuple
instead of throwing an exception when the generation fails.

The generation fails if the all the attempts to generate a value did not adhere
to the input type constraints.
The constraints attribute for an greater-than-20 integer generator can be:
One value of the type definition list is:
```erlang
{constraints, [{fun(X) -> X > 20 end, true}]}
```

A constraint is defined by a two-elements tuple,
a predicate, and boolean that specifies whether the constraint is strict.
That is, it tells whether the generation should fail if the constraint is violated or not.

Generation is a loop. The generator has a maximum number of tries.
The number of tries is a globally defined value, named `constraint_tries`.
It's initialized to `50`, but we can change through the options we pass to the test.

Here's how generation starts inside `safe_generate`:
```erlang
Instance = generate(Type, get('$constraint_tries'), none)
```

`generate` calls itself recursively.
Each time, it generates an instance and checks whether it satisfies the type constraint.
If it does, it returns it.
If not, it decreases the number of tries left and starts a new iteration.

If no valid instance is generated, generation fails with `cant_generate` error.
It returns `{error, {cant_generate, MFAs}}`.
`error` and `cant_generate` are atoms.
`MFAs` is the list of constraints and the booleans results of their checking.

The function that generates an instance is defined in the type list as well.
In the example at the beginning,
the type `union([binary(), lists:seq(1, 255)])` is a union of two types.
Here's a simplified inlined version of its generator:
```erlang
union_gen(Type) ->
  Choices = get_prop(env,Type),
  Pos = rand_int(1, length(Choices)),
  Type = lists:nth(Pos, Choices),
  {typed, Gen} = proper_types:get_prop(generator, Type),
  Gen(Type, proper:get_size(Type)).
```

`get_prop(env,Type)` reads the value of a tuple named `env` from the type list.
`Choices` contains the list `[binary(), lists:seq(1, 255)]`.
`Pos` is the index of either elements, it should be `1` or `2`.
Indexes start from `1` in Erlang.
If it's `1`, then `Type` is `binary`.

`binary` is also a type, which means it's a list of attributes.
`Gen` is the value of the key `generator` in `binary` type.

The `generator` attribute af a type contains a function that creates a randomly generated value.
For example, an integer generator can be defined as:
```erlang
integer_gen(Type, Size) ->
  {Low, High} = get_prop(env, Type),
  pproper_arith:smart_rand_int(Size, Low, High).
```

We can define custom generators by creating a new type and setting our own custom generator function
inside its defining list.

We can also create a complicated generator by returning a type instead of a value from this function.
If for example, instead of returning a number here, we return a type such as:
```erlang
integer_gen(Type, Size) ->
  {Low, High} = get_prop(env, Type),
  N = pproper_arith:smart_rand_int(Size, Low, High),
  [{generator, {typed, fun integer_gen/2}}, {constraints, [{fun(M) -> M + N > 20 end, true}]}].
```
The generator will generate an instance of the returned type and return it instead.

### Shrinking
When the generation loop stops because of a generated instance that failed the test,
shrinking starts as `shrink` is called.
PropEr tries to generate smaller values from the failed one.

Among the attributes inside the type list is one whose key is `shrinkers`.
Its value is a list of functions.

Here's a simplified logic for how `union` (the function used to create the type in the first example)
creates a type structure.
```erlang
union(RawChoices) ->
  Choices = [cook_outer(C) || C <- RawChoices],
  ?BASIC([
    {env, Choices},
    {generator, {typed, fun union_gen/1}},
    {is_instance, {typed, fun union_is_instance/2}},
    {shrinkers, [fun union_shrinker_1/3, fun union_shrinker_2/3]}
  ]).
```

It defines two shrinkers, `union_shrinker_1` and `union_shrinker_2`.

Same as with generators, we can define custom shrinkers by
creating a type structure and defining custom shrinking functions.

`proper_shrink:shrink` fetches the shrinkers of the given type,
either from the predefined ones if the type is standard,
or from the value of `shrinker` inside the type list.

Here's a simplified code of how standard shrinkers are fetched depending on the kind:
```erlang
Kind = proper_types:get_prop(kind, Type),
StandardShrinkers =
  case Kind of
    basic -> [];
    wrapper -> [fun alternate_shrinker/3, fun unwrap_shrinker/3];
    constructed ->
      case proper_types:get_prop(shrink_to_parts, Type) of
        true -> [fun to_part_shrinker/3, fun parts_shrinker/3, fun in_shrinker/3];
        false -> [fun parts_shrinker/3, fun in_shrinker/3]
      end;
    container -> [fun split_shrinker/3, fun remove_shrinker/3, fun elements_shrinker/3];
    _Other -> []
  end,
```

The main logic of `shrink` function is:
```erlang
{Shrinks,MinImmTestCase} = fix_shrink(ImmTestCase, StrTest, Reason, 0, MaxShrinks, Opts)
rerun(Test, true, MinImmTestCase)
```

`fix_shrink` calculates a list `MinImmTestCase` that contains simplified values.
It returns a tuple containing the number of effectuated shrinks and the list of shrunk values.
`shrink` extracts this list and reruns the testing on these instances
in order to create a result and return it.

`fix_shrink` starts a shrinking loop.
It calls itself recursively, each time with a smaller `ShrinksLeft` value.
Initially, this value is set to `MaxShrinks`.
The loop ends when it reaches `0`.

Inside an iteration of this loop,
the library pics an element that failed to pass the property and calculates a list of its shrunk values.

If all these shrunk values pass the property check, the element cannot be shrunk further.
PropEr puts it in the list of minimally-shrunk values, named `Shrinked`,
and moves on to the next value that fails the property.

If one shrunk value fails the property for the same reason as the original value,
the library puts it on the list of candidates for shrinking in place of the original value,
and rerun the iteration.
The next iteration will take this shrunk value and tries to shrink it further.

PropEr compares the failure reason for the shrunk value with the failure reason for the original
value using pattern matching:
```erlang
same_fail_reason(SameReason, SameReason) ->
  true;
same_fail_reason(_, _) ->
  false.
```

If both reasons are equal, it returns true.
If not, it returns false.

The library might reach the maximum number of shrinkings by shrinking a value over and over
using only the first shrinker in the list.
It might also use all the shrinkers and fail to shrink the original value.

PropEr uses `proper_shrink:shrink` to create a list of simplified values that potentially fail the property
from an instance that fails the property.

`proper_shrink:shrink` is defined as:
```erlang
-spec shrink(proper_gen:imm_instance(), proper_types:type(), state()) -> {[proper_gen:imm_instance()],state()}.
```

It takes a generated instance, its type, and a state.
PropEr uses the type to filter out shrinking results that do not satisfy the type constraints:
```erlang
SatisfiesAll =
  fun(Instance) ->
    case find_prop(constraints, Type) of
      {ok, Constraints} -> satisfies_all_1(Constraints, Instance);
      error -> true
  end,
{NewImmInstances,NewLookup} = proper_arith:filter(SatisfiesAll, DirtyImmInstances),
```
`DirtyImmInstances` is the list returned by the shrinker.
`SatisfiesAll` is a predicate that returns true when a value satisfies the type constraints.

Depending on how you see it, passing both the type and the value
can be either a dirty hack or a source of flexibility.
We can see it as an idea that does not fit well with Erlang model.

Maybe we think in an idiomatic OOP way.
Knowledge of the type is intrinsic to objects.
We cannot ask an object. We should send it a message.
We can also put on the hat of an idealist programmer and say those function arguments
should all be at the same level of abstraction.
Having a state and a type, or a state and a value, means the design
needs to be improved.

Putting a hacker hat on, we can say that having a structure to specify the type
allows us to have specific constraints. Think of a type of all integers other than 5, 9, 8.
Such a type is not easy to define.
But, with a structure, we can add a function that directs shrinking and generation
to ignore these numbers, and to generate another value when one of them appears.
After all, an abstraction level is subjective.
For someone somewhere, the value, the type, and the state belong to the same level.

Me, I will put on the pragmatic hat. It works, it's easy to understand and test,
and, well, it's encapsulated enough to make future changes easy.

`proper_shrink:shrink` returns a list of instances and a state.
This state is used to track shrinking progress between iterations
(remember, shrinking is a loop).

It's `init` when we start shrinking a new original value.
This makes the shrinking function pick the first shrinker and start shrinking.

It's `done` when a shrinker cannot shrink a value further.
This makes the shrinking function tries the next shrinker or moves to the next
original value that fails the property.

It's a structure that includes the context of the shrunk value when the shrinking
is in progress.
If the value is constructed, and the shrinker chooses the first part as a shrunk value,
the context will contain the other parts.

When the property is a conjunction of sub-properties.
PropEr uses `shrink_all` instead of `shrink`.
This function executes `shrink` for each property/reason/failed instance.
Then, it returns a list of shrunk values.
If a property of these sub-properties succeeds for the given input,
only the failed properties are passed to the shrinks functions.

Similarly to `proper_shrink:shrink`, a Shrinker is a function defined as:
```erlang
-spec shrinker(imm_instance(), type(), state()) ->  {[imm_instance()],state()}.
```
It also takes an instance, its type, and a state.
It returns a list of shrunk values and a state.
That way, it integrates with the shrinking loop.
The state returned by the shrinker is the state returned by the iteration,
which is also the state which orients the library on what to do nex
(either starting a new iteration with same/new shrinker or finishing shrinking and
moving to the next value).

### Multi-workers execution
When the number of workers is not `0`,
each worker gets a number of checks to perform sequentially.
After finishing, it sends the result as a message to the main worker.

Workers in Erlang communicate through messages.
The function that starts testing keeps listening for the messages of spawned workers.
With each message, it merges the result with the existing result.

The result is initialized as:
```erlang
InitialResult = #pass{samples = [], printers = [], actions = []},
```

Samples are added when the main worker receives a successful result from a testing worker.
If the worker sends a failure result instead (if an instance generated by that worker
fails the property), the main worker:
  * Sends a message (a tuple whose head is `failed_test`) to other workers communicating a failure
  * Other workers stop testing and send back their generated values
  * Returns `#fail` result

The messages between the main worker and the workers that run the tests are tuples.
The first element in each tuple is an atom that describe the type of the message.
It's `worker_msg` if the message is sent from a testing worker to the main worker.
When the message is from a main worker to a testing worker, it's `failed_test`.

Here how the main worker waits for the testing workers messages:
```erlang
receive
  {worker_msg, #pass{performed = PassedRcvd, samples = SamplesRcvd}, From, Id} ->
    -- ...

  {worker_msg, #fail{performed = FailedOn} = Received, From, Id} ->
    -- ...
```
`receive` starts listening.
The first handler handles messages from workers that finish their tests successfully.
The second handles messages from workers that failed.

We define a value for the attribute named `strategy_fun` inside the options
to split the load of tests.
The value of this attribute is:
```erlang
%% A function that given a number of tests and a number of workers, splits
%% the load in the form of a list of tuples with the first element as the
%% starting test and the second element as the number of tests to do from there on.
```

PropEr provides a default function that splits the test equally between the workers.
Given `NumTests = 150` and `NumWorkers = 2`, it returns:
```erlang
[{1, 74}, {75, 149}]
```
Each tuple in the result describes a range of tests to be handled by a worker.

PropEr handles pure and impure properties differently.
Inside the options structure, we can define an attribute `property_type`,
which can be either `pure` or `impure`.
Both here are atoms.
In Erlang we use atoms to model sum types.
The benefit/drawback, depending on how you want to see it,
is that all atoms are of one type, as are all other values.

`property_type` type definition is:
```erlang
-type purity() :: 'pure' | 'impure'.
```

The documentation of `parallel_perfom` says:
```erlang
%% When testing impure properties, PropEr will start a node for every worker that will be
%% spawned in order to avoid test collisions between them.
```

When the property is pure, PropEr starts a worker that runs the function that performs the tests
That is, it executes `spawn_link(Fun)`.
[`spawn_link`](https://www.erlang.org/doc/man/erlang.html#spawn_link-1)
is a function used to create a new process that is linked to the current process.

> Returns the process identifier of a new process started by the application of Fun to the empty list [].
> A link is created between the calling process and the new process, atomically. Otherwise works like spawn/3.

If it's impure, PropEr starts a node for each worker before testing.
Then, it executes and attaches each worker to a node to start testing.

PropEr starts "remote nodes to ensure testing will not crash the BEAM".
A node here, as opposed to a worker for pure properties,
creates a new runtime environment that's separated from the one directing the testing.
PropEr uses [`peer:start_link`](https://www.erlang.org/doc/man/peer.html) for this.

Such a concept of spawning a new runtime environment that acts like a worker
in the current environment is made to distribute the execution among many machines,
all while writing code as if it is running on a single BEAM instance.

Here, it executes another variant of `spawn_link`, one that takes the node
as well as the function that perform the tests.
[`spawn_link(Node, Fun)`](https://www.erlang.org/doc/man/erlang.html#spawn_link-2)
> Returns the process identifier (pid) of a new process started by the application of
> Fun to the empty list [] on Node. A link is created between the calling process and the new process,
> atomically. If Node does not exist, a useless pid is returned and an exit signal with reason
> noconnection is sent to the calling process. Otherwise works like spawn/3.
