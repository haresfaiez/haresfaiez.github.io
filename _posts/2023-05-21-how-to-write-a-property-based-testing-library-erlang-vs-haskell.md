---
layout:   post
comments: true
title:    "How to write a property based testing library: Erlang vs Haskell"
date:     2023-05-21 12:02:00 +0100
tags:     featured
---

[Property-based testing](https://en.wikipedia.org/wiki/Software_testing#Property_testing)
is a test automation approach that checks invariants instead of concrete examples.
When a test subject, a component or a function for example, has a huge input space
(strings, real numbers, combinations of parameters, ...),
then making sure our code returns a valid result for a variety of inputs requires
a lot of example-based tests.
Testing every combination of parameters, or every conceivable string, will take forever.
The drawback of writing and maintaining these tests outweigh
the benefit of having tests in the first place.

Writing property-based tests increases our confidence in the code without that many inconveniences.
Testing an array sorting function is a classic use case of this kind of testing.
We define a property that compares the sum of result array elements
to the sum of initial array elements.
If they're different, our sorting function needs some work.

A property-based testing library builds different shapes of arrays:
an empty array, arrays with one element, arrays with huge numbers of elements,
with duplicated elements, with negative numbers, ...
It checks the property for each generated value.
When a generated array fails the property, the library tries to simplify it,
or shrink it if we want to use the right term.
It returns the simplest counterexample.

It's interesting to see how different languages implement such a library.
Both [Haskell](https://en.wikipedia.org/wiki/Haskell)
and [Erlang](https://en.wikipedia.org/wiki/Erlang_(programming_language))
are functional programming languages.
They embrace ideas like purity and immutability.
But, they approach the model differently.
Haskell is typed.
Erlang is not.
Haskell has native support for group theory constructs.
Erlang is message-based.
Haskell embraces lazy evaluation.
Erlang provides primitive constructs for concurrent execution and fault-tolerant platform.
Haskell has lazy evaluation by default.

I'll try to describe how each language implements a property-based testing library.
I'll talk about the global design. I won't put all the edge cases.
I'm trying to make the post intelligible even for people not familiar with the languages.
Write to me if something can be improved.


## QuickCheck
[Quickchek](https://github.com/nick8325/quickcheck) is a Haskell property-based testing library.

Properties are usually functions that return boolean values.
Let's say we have a function `reverse` that reverses an array of integers.
We can define a property `prop_reverse` that takes an array,
reverses it twice, and compares it to the original array.

```haskell
prop_reverse inputArray = (reverse (reverse inputArray)) == inputArray
```

We run the test using `quickCheck`:
```haskell
>>> quickCheck (withMaxSuccess 10000 prop_reverse)
+++ OK, passed 10000 tests.
```

`quickCheck` needs a property and a set of testing parameters to start its engine.
What quickCheck calls an engine is a loop.
In each iteration, it builds an input candidate, uses it to check the property,
then decides whether:
  * to stop testing and fail
  * to stop testing and succeed
  * to continue testing (run another iteration, generate another input, and check it)

This engine is run by a function named `test`,
defined as `test :: State -> Property -> IO Result`.
It takes a state `State` and a property `Property`,
tests the property, creates a next state,
and calls itself recursively.

We'll go through the types.

### Result
Each iteration in the engine loop returns a `Result` variable.
The value returned by the last iteration is the same returned by the engine at the end of testing.

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

A result is:
 * `Success` after a successful iteration, or a successful property testing.
 * `GaveUp` after reaching a threshold of discarded tests.
    A test is discarded when an error occurs,
    like a failure to generate an input or an exception during the execution of the property.
 * `Failure` after a failed iteration, or a failed property testing.
 * `NoExpectedFailure` when the property should have failed, but did not.

 An example of a property that should fail is:
 ```haskell
our_prop n = expectFailure (n === n + 1)
```

Here we're comparing an integer `n` to `n + 1`.

`expectFailure` creates a testing result.
This value provides more context on how to check the test than a simple boolean result.
The resulting structure will contain an attribute `expect` whose value is `True`.

We can return either a boolean value or such a result value.
This result is also named `Result`, but it's a different structure than the one we just saw.
Here's how the iteration result, the first we introduced,
is created from the property result, the one returned by `our_prop`.

The returned value is the iteration result.
`res` is the value returned by the property.

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
 where
```

### State
Haskell functions are pure.
A new state is built after each engine iteration
and passed to the next iteration.
This state is a data structure that reifies the progress.

It stores what persists between iterations:
the number of tests done, the number of successful tests,
the number of required iterations, a reference to a terminal to notify the
users about the testing progress, ...

The state is initialized before testing starts.
Then, after checking the property with a new instance,
it's recomputed and passed to the next iteration.

### Property and Testable
Properties are usually functions or propositions.
`prop_reverse` above is a function.

`property` here is a proposition:
```haskell
cyclicList_prop = forAll cyclicList $ \(xs) -> and $ zipWith (==) xs (drop 2 xs)
```

This property makes sure that a given generator, `cyclicList`,
produces arrays of integers with period 2.
The produced array should be a repetition of two elements.

Functions and propositions are `Testable` instances.
A `Property` can be seen as a bridge between a `Testable` instance and a property generator.
A property generator is a variable that executes the engine iterations.

In this property:
```haskell
prop_reverse inputArray = (reverse (reverse inputArray)) == inputArray
```

The property generator holds a reference to an array generator
and a reference to the checking function.
It generates a value, checks it on the property, and creates a result.

`Testable` is a class of values that QuickCheck knows how to transform into
a `Property` value or a `Result` value.

`Property` type is defined by:
```haskell
newtype Property = MkProperty { unProperty :: Gen Prop }
```

There are two ways to create a property.
We can create it if we have a property generator, `Gen Prop`.
Or, if we have `Testable` instance.

We'll see step by step why we need three concepts, `Property`, `Prop`, and `Testable`.

### The heartbeat of the engine
This expression in the heart of the engine:
```haskell
(unProp (unGen (unProperty f_or_cov) rnd1 size))
```

It's directed by the property generator.
It evaluates to `Rose Result`.

It's a mere unfolding of folded values.
We first call `unProperty` on `f_or_cov`, which is a `Property` instance.
We unfold the result with `unGen` to get a `Prop` value.
We unfold what we find with `unProp` to get a `Rose Result` value.

As the wise guys up on the mountains would say, folding is unfolding.
Let's see how such a folded value is created.

### Gen
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
that is `generator = MkGen ourUnGenFunction`.
This function takes a random number generator, `QCGen`,
and a size integer.
It returns a generated instance.
Both, the random seed and the size, are defined in the state passed between iterations.
Size is taken from the options we pass to `quickCheck` in the first place.
Its default value is `30`. It orients generators on how complicated the generator instances can be.

The library defines generators for basic types, like `Int`.
It can also create generators for types that can be constructed
(arrays, sum, and product types for example).
And if we want a custom generator, we can create one.

QuickCheck knows how to create a property generator, `Gen Prop`, if it can
get a generator for the input type.
In `prop_reverse`, QuickCheck has already an `Int` generator and an array generator.
It builds a property generator.
For the `cyclicList_prop`, we define an input generator, `cyclicList`,
and give it quickCheck.

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
Let's say `gen` is our `Gen a` generator. `f` is a property,
a function whose signature is `Testable prop => a -> prop`.
It takes a value of type `a`. It returns a `Testable` value.
Usually, a boolean or a `Result` structure.

We create a `Gen Prop` instance by defining an `unGen` function.
It takes a random number generator, a size,
and it has access to the input generator `Gen a`, or `gen` in the line of code here.

So, it generates an input by calling `unGen` of `Gen a` with the given random number generator and size,
gets an instance, tests it, and creates a result.

The definition of this function in the code looks like this:
```haskell
gen >>= \x -> unProperty $ shrinking shrinker x f
```

`x` is the input to the function. `f` is the property.
As you see here, we're not calling `f x` directly.
We're starting a shrinking process instead.

`shriking` calls `f x` internally.
It checks the property `f` for the generated input `x`.
Then if the result is `True`, it does nothing.
It just returns the value returned by `f`.
If the result is false, it starts a shrinking process to simplify `x`.

`shrinking` builds a [rose tree](https://en.wikipedia.org/wiki/Rose_tree).
The root node contains the result of applying the property to `x`, the originally generated value.
The children contain the results of applying the property to shrunk values of the original value.
The grandchildren are the results of applying the property to shrunk values of shrunk values.
And, so it goes.
The tree building stops when a shanked element passes the property, either returning `True` or a successful result.

As the value returned by the property is a `Testable` instance, we get a tree of `Testable` instances.
The library transforms it into a tree of `Gen Prop` instances.

Node by node, it transforms each value into a `Property` instance (see first section).
We can call this a shadow property, or a null property.
Calling `unGen` returns the initial value, `f x`, no matter which input we pass in.

And same, we call `unProp` on each `Gen Prop` element result,
and we get `Rose Result` which always contain
the result of applying the property.
A boolean value is transformed into a result structure.
We end up with a tree `Rose` of `Rose Result` nodes, or `Rose (Rose Result)`.

### Rose Result
`Rose` is defined as `Rose = MkRose a [Rose a]`.
The tree, `Rose (Rose Result)`, we get, is a flat structure.
It's an array built following a [depth-first traversal](https://en.wikipedia.org/wiki/Tree_traversal#Depth-first_search) of the tree.

If `res` is a failure,
shrinking loop kicks in to find the smallest value that fails the property.
This value is called a local minimum.
The function basically through the children from right to left and tests each element.
If the property succeeds, it checks the adjacent nodes.
If it fails, it goes on checking the element children nodes.
It stops when a threshold of attempts is reached or after testing all the results available.

This is a good example of lazy evaluation in Haskell.
QuickCheck does not build the entire tree in the first place.
Neither the tree of `Testable` elements, nor that of `Gen Prop` elements,
and neither this of `Rose Result` elements.

It pretends to build them.
When we want to see what's inside a node,
only then Haskell builds only that node.
It creates a `Testable` instance, a `Gen Prop` instance, and a `Rose Result` instance.
But, it does not create its children.
It builds them when we try to read them.

With a rose tree of `Rose Result`, or `Rose (Rose Result)`.
QuickCheck uses a function `joinRose` to transform it into a `Rose Result` value.
That is:
```erlang
joinRose (MkRose (MkRose x ts) tts) =  MkRose x (map joinRose tts ++ ts)
```

With this returned result, the engine decides whether to start a new iteration
or to end the testing.


## PropEr
[`PropEr`](https://github.com/proper-testing/proper) is the most-used Erlang
property-based testing library.

We check a property by calling `quickheck`:

```erlang
prop_enc_dec() ->
  ?FORALL(
    Msg,
    union([binary(), lists:seq(1, 255)]),
    base64_decode(base64_encode(Msg)) =:= Msg
  ).

quickcheck(prop_enc_dec(), [{numtests,10000}])
```

We create the property `prop_enc_dec` using `?FORALL` macro.
`union([binary(), lists:seq(1, 255)])` is the input type.

Here the input is either an array that contains the sequence of numbers
from 1 to 255,
or a binary value (also a list that contains bytes, values between 0 and 255, generated randomly).
Erlang transforms the first possible value also to a binary.
It maps every element to a byte and joins them.
The property checks whether a given `Msg` stays the same after
encoding and decoding it in base 64.


### What's a property
Erlang offers a good meta-programming system.
The library uses [macros](https://en.wikipedia.org/wiki/Macro_(computer_science)) heavily.

A property in PropEr is a structure or a tuple in Erlang terms.
`?FORALL` macro above translates into this structure:
```erlang
{
  forall,
  union([binary(), lists:seq(1, 255)]),
  fun(X) -> base64_decode(base64_encode(Msg)) =:= Msg end
}.
```
The first element is an atom that guides the testing.
It can be `exists`, `conjunction`, `implies`, or `timeout`.
The difference is in how to create a result after testing a generated value.

The first element can also be `exists`, `conjunction`, `trapexit`,or `timeout`.
When the first element is `exists`, the options should contain two attributes, `search_steps` and `search_strategy`.
This is a particular case of targeted search. I'll introduce it in the next post.

When it's `conjunction`, the property is in the form `{conjunction, SubProperties}`.
`Subproperties` is a list of properties.
Such property passes when all sub-properties pass.

When it's `trapexit`, ProEr expects the property to have uncaught exceptions or to emit an exit signal.
It configures the system to get an `EXIT` message when the tested function emits an exit signal.
Then, it spawns a worker to execute the check and send the result.
And, it waits for this result.

An example of such properties can be:
```erlang
 ?_failsWith([20], ?FORALL(X, pos_integer(), ?TRAPEXIT(creator(X) =:= ok))),
```

When it's `timeout`, it spawns a new worker to execute the property
and expect the result before a given timeout.
Here's how it's implemented:
```erlang
run({timeout, Limit, Prop}, Ctx, Opts) ->
    Self = self(),
    Child = spawn_link_migrate(undefined, fun() -> child(Self, Prop, Ctx, Opts) end),
    receive
	{result, RecvResult} -> RecvResult
    after Limit ->
        unlink(Child),
        exit(Child, kill),
        clear_mailbox(),
        create_fail_result(Ctx, time_out)
    end;
```

`child(...)` runs the property check and sends the result back to the father,
the worker that manages the testing:
```erlang
child(Father, Prop, Ctx, Opts) ->
    Result = force(Prop, Ctx, Opts),
    Father ! {result,Result},
    ok.
```

The second element in the property tuple is the input type.
In our example, we're creating a type by joining a type, `binary()`, with a value, the sequence.
The concept of a type in PropEr is not the usual one.
A type in Erlang is a structure that contains generators, constraints, shrinkers, and other
attributes that guide testing.

The last element is a check function.
The check takes a generated input and returns a boolean value.
It can also return another property, a structure like `{forall, ..., ...}`.
This allows us to create rich properties.
When a test structure is returned, a new testing iteration starts to generate
and check a new value.

Let's say
```erlang
{forall, integer(), (N) -> {forall, integer(), (M) -> N + diff(N, M) =:= M } }
```

or an implication
```erlang
?FORALL({I,L}, {integer(),list(integer())}, ?IMPLIES(no_duplicates(L), not lists:member(I,lists:delete(I,L))))
```

or
```erlang
?FORALL(L, list(atom()), ?WHENFAIL(inc_temp(), length(L) < 5))
```

### Sequential tests execution
`quickcheck` takes a list of options in addition to a property.
There are many other options we can specify.
PropEr add the ones we don't pass in and sets default values for them.

In the example above, it gets `{numtests,10000}`, the number of inputs to generate and check.
If the library generates 10000 inputs.
If all of them pass the test, then testing stops, and the property is successful.

Another option we can specify is `numworkers`, the number of workers.
This option:
```erlang
Specifies the number of workers to spawn when performing the tests (defaults to 0).
Each worker gets their own share of the total number of tests to perform.
```

A worker in Elang is a construct close to a green thread.
It performs concurrent tasks.
Erlang core philosophy lies in the implementation of these workers. They have a well-defined
interface, they communicate through messages,
and they're managed by [OTP](https://www.erlang.org/doc/design_principles/des_princ.html).
This virtual machine doesn't let crashes and errors propagate through the systems.
It can restart crashed workers and resend them missed messages.

When the number of workers is `0`, test execution is sequential.
One worker handles all the needed work.

The logic is defined inside a function named `perform`.
This function calls itself recursively until it reaches the number of required checks,
or until a generated instance fails the property check.
Each iteration generates an instance using the given types and tests it.

If the testing succeeds, a `#pass` structure is created, `#pass{}`.

If the input fails to pass the property, a `#fail` structure is created,
`#fail{reason = Reason, bound = lists:reverse(Bound)}`.
`Reason` is `false_prop` for simple properties.

`bound` contains the list of generated values that failed to pass the property.
It contains one element when the property check returns a boolean value.
And, it contains as many instances that failed the test when the check returns a property.

### Generation
PropEr puts generation logic inside a module named `proper_gen`.

To generate a new instance, PropEr runs:
```erlang
case proper_gen:safe_generate(RawType) of
    {ok, ImmInstance} ->
      Instance = proper_gen:clean_instance(ImmInstance),
    {error, Resaon} ->
      ...
```

`ImmInstance` is the generated value.
`Instance` is the value it passes to the property.
The generated value is wrapped in a context, that's why we need to call `clean_instance`.

But usually, `Instance` is the same as `ImmInstance`.
If the value is constructed, the generated value will be a tuple
containing the generated parts as well as the final value.
We'll see in the next why we need this context.

`proper_gen:safe_generate` calls `proper_gen:generate`.
The difference is that the `safe_` variant returns an `error` tuple
instead of throwing an exception when generation fails.

The generation fails if the all the attempts to generate a value do not conform
the type constraints.
Or, if the input we want to generate is itself a function, but with an unsupported arity
(we'll get back to this kind of input in the next post).
Or, if the type we provide cannot be parsed by PropEr type server.
As we have said, Erlang has good meta-programming support.
We can pass a string containing a type definition instead of a reference to an existing type.
Parsing this string might fail.

As we said in the previous section, the second element of the property tuple is the type.
It's a structure. Usually, it's a list of key/value attributes.
The constraints we just talked about are a list of tuples.
Each one contains a predicate and boolean specifying whether the constraint is strict or not.
That is, whether generation fails if the constraint is violated or not.

Generation is a loop. The generator is given a maximum number of tries.
The number of tries is a globally defined value, named `constraint_tries`.
It's initialized to `50`. We can change through the options we pass to the test.

Here's how generation starts:
```erlang
Instance = generate(Type, get('$constraint_tries'), none)
```

In each iteration, it generates an instance and checks whether it satisfies the type constraint.
If it does, it returns it.
If not, it decreases the number of tries left and starts a new iteration.
If no valid instance is generated, generation fails with `cant_generate` error, `{error, {cant_generate, MFAs}}`.
`error` and `cant_generate` are atoms. `MFAs` is the list of constraints and the results of their checking.

In the example at the beginning of the section,
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

`get_prop(env,Type)` reads the value of a tuple named `env` of the type.
`Choices` contains the list `[binary(), lists:seq(1, 255)]`.
`Pos` is the index of either the elements, let's say `1`, the first element.
Indexes start from `1` in Erlang.
`Type` is `binary`.
`Gen` is a function. It's a value of the key `generator` in `binary` type.

The `generator` attribute contains a function that creates a randomly generated value.
For example, an integer generator is defined as:
```erlang
integer_gen(Type, Size) ->
    {Low, High} = get_prop(env, Type),
    pproper_arith:smart_rand_int(Size, Low, High).
```

We can define custom generators by creating a new type, with a custom generator function.
We can also create a complicated generator by returning a type instead of a value from this function.
If for example, instead of returning a number here, we return a type such as
```erlang
[{generator, {typed, fun integer_gen/2}}]
```
The generator module will generate an instance of this value and return it instead.

The type structure also contains an attribute named `kind`, whose value can be:
```erlang
-type type_kind() :: 'basic' | 'wrapper' | 'constructed' | 'container' | atom().
```

This value guides generation.
A constructed type, one whose kind is `constructed`, should define `parts_type` and `combine` attributes.
To generate an instance of such type, the generated calls `generate` with the type of the parts
and get a list of instances back.
It calls `clean_instance` to remove their contexts.
Then, it calls the value of `combine` attribute which combines them into one value.
The generation of instances of the other kinds is similar.

### Shrinking
After generating and checking as many instances as needed, PropEr analyzes the result.
It decides whether to start shrinking or to finish testing.

If the check fails for some instance, that is if the returned value is a `#fail` structure,
shrinking starts.
The library tries to generate smaller values from the failed one.

The type list contains a tuple whose key is `shrinkers`.
The value in this tuple is a list of shrinkers functions.
Here's a simplified logic for how `union`, the function used to create the type in the first example,
creates a type structure.
It defines two shrinkers here, `union_shrinker_1` and `union_shrinker_2`.
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

As as we generators, we can define custom shrinkers for the input type by
creating a type structure and defining custom shrinking functions.

`proper_shrink:shrink` fetches the shrinkers of the given type,
either from the predefined ones if the type is standard,
or from the value of `shrinker` tuple in the type list.
Usually, there are two or three of them.

A Shrinker is a function defined as:
```erlang
-spec shrinker(proper_gen:imm_instance(), proper_types:type(), state()) ->  {[proper_gen:imm_instance()],state()}.
```

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

Then, `fix_shrink` calculates a list `MinImmTestCase` that contains simplified values.
It returns a tuple containing the number of effectuated shrinks and the list of shrunk values.
Finally, it reruns the testing on these instances to create a result and return it.

`fix_shrink` starts a shrinking loop.
It calls itself recursively, each time with a smaller `ShrinksLeft` value.
It finishes when this value reaches `0`.

Inside an iteration of this loop,
the library pics an element that failed to pass the property and calculates a list of its shrunk value.
If these shrunk values pass the property check, the element cannot be shrunk further.
The function puts it in the list of minimally-shrunk values, named `Shrinked`,
list and moves to the next value that fails the property.
If it does fails the property for the same reason as the original value,
the library puts it on the list of candidates for shrinking in place of the original value,
and starts another iteration.
The next iteration will take this shrunk value and tries to shrink it further.

PropEr compares the failure reason for the shrunk value with the failure reason for the original
value using pattern matching:
```erlang
same_fail_reason(SameReason, SameReason) ->
    true;
same_fail_reason(_, _) ->
    false.
```

If both reasons are equal, `SameReason`, then it returns true.
Elsewhere, it returns false.

PropEr defines `proper_shrink` to create a list of simplified values that potentially fail the property
from an instance that fails the property.

Same as shrinkers, `proper_shrink:shrink` is defined as:
```erlang
-spec shrink(proper_gen:imm_instance(), proper_types:type(), state()) -> {[proper_gen:imm_instance()],state()}.
```
It takes the instance, its type, and a state.
Depending on how you see it, the specification of a type in addition to the value
can be a dirty hack or a source of flexibility.

PropEr uses the type to filter out shrinking results that do not satisfy the type constraints.

As you see here:
```erlang
    SatisfiesAll =
      fun(Instance) ->
          case find_prop(constraints, Type) of
            {ok, Constraints} -> satisfies_all_1(Constraints, Instance);
            error -> true
      end,
    {NewImmInstances,NewLookup} = proper_arith:filter(SatisfiesAll, DirtyImmInstances),
```
`DirtyImmInstances` is the result of shrinking.
`SatisfiesAll` is a predicate that returns true when a value satisfies the type constraints.

We can see it as an idea that does not fit well with Erlang model.
Maybe we think in an idiomatic OOP way.
Knowledge of the type is intrinsic to objects.
We cannot ask an object. We should send it a message and go on.
We can also put on the hat of an idealist programmer and say those function arguments
should all be at the same level of abstraction.

Putting a hacker hat on, we can say that having a structure to specify the type
allows us to have specific constraints. Think of a type of all integers other than 5, 9, 8.
Such a type is not easy to define. But, with a structure here, we can add a function that directs shrinking and generation
to ignore such numbers, and to generate another value if one of them appears.
After all, an abstraction level is abstract and subjective.
In some minds, the value, the type, and the state belong to the same level.

Me, I will put on the pragmatic programmer hat. It works, it's easy to understand and test,
and, well, it's well encapsulated enough to make future changes easy.

`proper_shrink:shrink` returns a list of instances and a state.
As said before, shrinking is a loop.
This state is used to track shrinking progress between iterations.

It's `init` when shrinking a new original value starts.
This makes the shrinking function pick the first shrinker and start shrinking.

It's `done` when a shrinker cannot shrink a value further.
This makes the shrinking function tries the new shrinker or moves to the next
original value that fails the property.

It's a structure that includes the context of the shrunk value otherwise.
If the value is constructed, and the shrinker chooses the first part as a shrunk value,
the context will contain the other parts.

When the property is a conjunction of sub-properties.
PropEr uses `shrink_all` instead of `shrink`.
This function executes `shrink` for each property/reason/failed instance.
Then, it returns a list of shrunk values.
If a property of these sub-properties succeeds for the given input,
only the failed properties are passed to the shrinks functions.

### Multi-workers execution
When the number of workers is not `0`, ProEr splits them.
Each worker gets a number of checks to perform sequentially and sends the result
as a message back to the main worker.

Workers in Erlang communicate through messages.
The function that starts testing workers keeps listening for their message.
With each message, it merges the result with the existing result.
Then, it adds samples if all the instances passed the test.
Or, if some instances failed:
  * Sends a message, a tuple whose head is `failed_test`, to other workers communicating a failure
  * Other workers stop testing and send back generated values
  * Returns `#fail` result

The result is initialized as:
```erlang
InitialResult = #pass{samples = [], printers = [], actions = []},
```

These messages between the main worker and the workers that run tests are tuples.
The first element in each tuple is an atom.
It is `worker_msg` if it's sent from a testing worker to the main worker.
Otherwise, it's `failed_test`.
Using atoms, then matching for functions definition is very common.

Here for example we have:
```erlang
receive
    {worker_msg, #pass{performed = PassedRcvd, samples = SamplesRcvd}, From, Id} ->
        -- ...

    {worker_msg, #fail{performed = FailedOn} = Received, From, Id} ->
        -- ...
```
`receive` starts listening for messages.
The first handler handles messages from the workers that finished their tests successfully.
The second handles messages from workers that failed.

This is another way of implementing listeners.
Usually, in OOP languages, there's a new class for each message.
The listener there defines a new method for each class.

We can set an attribute, `strategy_fun`, inside the options to split the load of tests.
The value of this attribute is:
```erlang
%% A function that given a number of tests and a number of workers, splits
%% the load in the form of a list of tuples with the first element as the
%% starting test and the second element as the number of tests to do from there on.
```

PropEr provides a default strategy function that splits the test equally between the workers.
If given `NumTests = 150` and `NumWorkers = 2`, it returns
```erlang
[{1, 74}, {75, 149}]
```
Each tuple in the result describes a range of tests to be handled by a worker.

PropEr handles pure and impure properties differently.
Inside the options structure, we can define an attribute `property_type`,
which can be either `pure` or `impure`.
See, both here are atoms.
In Erlang we use atoms to model sum types.

`property_type` type definition is:
```erlang
-type purity() :: 'pure' | 'impure'.
```

The benefit/drawback, depending on how you want to see it,
is that all atoms are of one type, as are all other values.

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
