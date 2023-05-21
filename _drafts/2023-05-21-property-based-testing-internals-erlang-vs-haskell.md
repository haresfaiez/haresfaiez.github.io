---
layout:   post
comments: true
title:    "Property-based testing internals: Haskell vs Erlang"
date:     2022-05-21 12:02:00 +0100
tags:     featured
---

[Property-based testing](https://en.wikipedia.org/wiki/Software_testing#Property_testing)
an automated testing approach that checks code properties.
It's useful for tesing component with a huge input space.
We cannot example from all input classes.

Testing a function that sorts arrays is a classic use case.
A property compares the sum of the result elements to that of the input,
and make sure they're equals.
The framework builds different shapes of input arrays:
an empty array, arrays with one element, arrys with huge numbers of elements,
many with negative numbers, and so on.

Such framework is an interesting codebase to study.
Many features are worth analyzing.
I want to see how different languages define the logic.

I'll try to describe how the core of a property-based testing
framework works in two different functional languages.
Both [Haskell](https://en.wikipedia.org/wiki/Haskell)
and [Erlang](https://en.wikipedia.org/wiki/Erlang_(programming_language))
are functional programming langugages.
Both emcompass basic ideas like purity and immutability.
But, they approach the model differently.
Haskell is typed. Erlang is not.


## Quickcheck
[Quickchek](https://github.com/nick8325/quickcheck) is a Haskell property-based testing library.
https://begriffs.com/posts/2017-01-14-design-use-quickcheck.html
https://chrisdone.com/posts/data-typeable/


Properties are usually functions that returns boolean values.
Let's say we have a function `reverse` that reverses an array of integers.
We can define a property `prop_reverse`, that takes an input array,
reverses it twice, and compares it to the original array.
It should be the same.

```haskell
prop_reverse inputArray = (reverse (reverse inputArray)) == inputArray
```

We call `quickCheck` to verify the property:
```haskell
>>> quickCheck (withMaxSuccess 10000 prop_reverse)
+++ OK, passed 10000 tests.
```

`quickCheck` takes a property and some testing parameters.
Then, it starts an engine.
The engine is a loop that, in each iteration, builds an input candidate, checks the proprety,
and decides whether:
  * to stop testing and fail
  * to stop testing and suceed
  * to continue testing (generate and check another input)

The heart of this engine is a function named `test`,
defined as `test :: State -> Property -> IO Result`.
It takes a state and a property,
tests the property, creates a next state,
and calls itself recursively.

We'll go through the types in the function signature one by one.

### Result
*** `Result` is ...?
The result tells whether to stop or to continue testing.

*** The result returned by the loop in the end is either
`Success` A successful test run. create by doneTesting,
`GaveUp` Given up create by ,
`Failure` A failed test run,
or `NoExpectedFailure` A property that should have failed did not.

### State
The state is a data structure that specify the test progress.
Haskell functions are pure.
A new state is built after each engine in the iteration.
Then, it's passed to the next iteration.

In order to run another iteration, these condition should be true about the state:
 - should be false: `numSuccessTests st   >= maxSuccessTests st && isNothing (coverageConfidence st)`
 - should be false: `numDiscardedTests st >= maxDiscardedRatio st * max (numSuccessTests st) (maxSuccessTests st)`
 - failed test: res=`MkResult{ok = Just False}` and `(numShrinks, totFailed, lastFailed, res) <- foundFailure st' res ts`;`theOutput <- terminalOutput (terminal st')`;`if not (expect res)`
 - failed test: res=`MkResult{ok = Just False}` and `(numShrinks, totFailed, lastFailed, res) <- foundFailure st' res ts`;`theOutput <- terminalOutput (terminal st')`; and false `if not (expect res)`

*** `Test.hs/test/doneTesting` ...?
    (`numSuccessTests st   >= maxSuccessTests st && isNothing (coverageConfidence st)`) ...?

*** `Test.hs/test/giveUp` ...?
    (`numDiscardedTests st >= maxDiscardedRatio st * max (numSuccessTests st) (maxSuccessTests st)`) ...?

*** how state changes between iterations, what changes?: `let st' = st{ covera...`
*** why do we need to call `addCoverageCheck` in `runATest`/`f_or_cov`?

### Property and Testable
`Property` is defined as:
```haskell
newtype Property = MkProperty { unProperty :: Gen Prop }
  deriving (Typeable)
```

A `Property` can be seen as a bridge betwwen a `Testable` instance and a property generator.
By property generator, we mean an instance that evaluates the property inside an engine iteration
and gives us the outcome.

If we create a property generator, `Gen Prop`. We have `Property` instance.
Same, if we have a `Testable` instance, we can build a `Property` instance.
It's not obvious to create a property generator.
That's why we usually provide `Testable` values or values that Quickcheck knows
how to make them `Testable`.

Properties are usually functions or propositions.
Any type is accepted as long as it's a `Testable` instance.
First thing, Quickcheck transform the property into a `Property` (with uppercase `P`)
instance by calling `property` (with lowercase `p`).

Propositions are `Property` instances by definitions.
`forAll` forexample is defined as `forAll :: (Show a, Testable prop) => Gen a -> (a -> prop) -> Property`.
To create a property, we pass a generator and a function whose return type is a `Testable` instance.

When we define a property as:
```haskell
property = forAll cyclicList $ \(xs) -> and $ zipWith (==) xs (drop 2 xs)
```

This property makes sure that a given generator, `cyclicList`,
produces arrays of integers with period 2. That's it, the array is a repition of two elements.
The complicated part is the creation of a generator.

Internally, `forAll` uses these input to create a property generator
that generate an input using the first argument, passes it to the second argument,
and generates a result.
We'll talk more about how this is done later.

Functions, when they're given as properties to Quickcheck,
are transformed first into a `Testable` instance,
then into a `Property`.

The definition states that a function is a `Testable` instance.
In order to convert such instance to a `Property` instance that we can test
inside the engine, we call `property :: (a -> prop) -> Property`.

Transforming a function to a `Testable` instance is assured by a definition:
```haskell
instance (Arbitrary a, Show a, Testable prop) => Testable (a -> prop) where
  property f =
    propertyForAllShrinkShow arbitrary shrink (return . show) f
  propertyForAllShrinkShow gen shr shw f =
    -- gen :: Gen b, shr :: b -> [b], f :: b -> a -> prop
    -- Idea: Generate and shrink (b, a) as a pair
    propertyForAllShrinkShow
      (liftM2 (,) gen arbitrary)
      (liftShrink2 shr shrink)
      (\(x, y) -> shw x ++ [show y])
      (uncurry f)
```

This property, `prop_cyclic`, makes sure `cyclicList` defined below generates arrays where every two
elements are equals the next two:
```haskell
cyclicList :: Gen [Int]
cyclicList = do
  rec xs <- fmap (:ys) arbitrary
      ys <- fmap (:xs) arbitrary
  return xs

prop_cyclic :: Property
prop_cyclic =
  forAll (Blind <$> cyclicList) $ \(Blind xs) ->
    -- repeats with period 2
    and $ take 100 $ zipWith (==) xs (drop 2 xs)
```

*** `Testable` is ...?
`Testable`? {{{
`Testable` is a Haskell class:
we instanciate this class for certain types
```haskell
instance Testable Bool where
  property = property . liftBool

instance Testable Result where
  property = MkProperty . return . MkProp . protectResults . return
  ...
```
`Property` is `Testable`:
```haskell
instance Testable Property where
  property (MkProperty mp) = MkProperty (fmap protectProp mp)
```
}}}

### The heartbeat of the engine
At the heart of the engine iteration, there's this expression:
```haskell
(unProp (unGen (unProperty f_or_cov) rnd1 size))
```
, which evaluates to `Rose Result`.

We start with `f_or_cov`, which is a `Property` instance.
We unfold the property with `unProperty`, we unfold the result with `unGen`,
then we unfold what we find again with `unProp` to get a `Rose` value.
This expression is mere unfolding of a folded values.
We get `Gen Prop`, then `Prop`, and then `Rose Result`.
To understand unfolding, we'll study folding.

We start the unfolding by calling `unProperty` on `f_or_cov`, which is a `Property` instance.
We talked about `Property` instances above.
We said that a `Property` encapsulates a property generator, `Gen Prop`.
Keep in mind that `Prop` and `Property` are different types.
We'll discover why do we need both.

### Gen
`Gen` is a class with one function `unGen`:
```haskell
newtype Gen a = MkGen{
  unGen :: QCGen -> Int -> a -- ^ Run the generator on a particular seed.
}
```

*** `unGen` takes a random ...?

If we give Quickcheck propositions, it creates a `Gen Prop` from a `Gen a` instance, or `Gen [Int]`
in the sorted array example, and the given function.
If we give a function, it create a `Gen Prop` from the input type, `a`, and the given function.

In the second case, Quickcheck creates a generator for `a`.
The library defines generators for basic types and for types that can be constructed
from these basic types.
If we want a custom generator, we can create one as well.
We'll cover these generators in the next section.

The important takeaway is that in both cases, we have an input generator `Gen a` ,
and a function `a -> prop`, where `prop` is a `Testable` instance,
and the library builds a `Gen Prop`.

The function that do this task in defined as:
```haskell
Testable prop => Gen a -> (a -> [a]) -> (a -> prop) -> Property
```
The second argument, `(a -> [a])`, is a shrinker.
It's a function that takes a value and produces an array simplified values.
For example, it takes an array of integers and creates many arrays, each with a removed element,
it takes a big number and creates an array of smaller numbers,
and so on.
Usually, Quickcheck defines shrinkers for primitive types.

### Arbitrary
*** `Arbitrary` is ...?
To generate a value of type `a`, we need an insatnce `Gen a`.
This, we get after calling `arbitrary`.
Quickcheck defines a class `Arbitrary` that provides two functions,
`arbitrary :: Gen a` to generate input values,
and `shrink :: a -> [a]` to shrink them.

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

Quickcheck defines both functions for basic types: numbers, string, doubles, ...
For composite and custom-defined types, we can defined our generators and our shrinking.

*** To define a shrinker ...?
Also, from the documentation:
```haskell
-- We can then define 'shrink' as follows:
--
-- > shrink Nil = []
-- > shrink (Branch x l r) =
-- >   -- shrink Branch to Nil
-- >   [Nil] ++
-- >   -- shrink to subterms
-- >   [l, r] ++
-- >   -- recursively shrink subterms
-- >   [Branch x' l' r' | (x', l', r') <- shrink (x, l, r)]
```

### Property generators
A simplified version of what happens during the creation of a property generator can look like this:
```haskell
gen >>= (\x -> unProperty $ shrinking shrinker x f))
```

`gen` is our `Gen a` generator. `f` is the property, `a -> prop`.

`gen >>= \x -> ...` creates a `Gen Prop` instance.
We can build a `Gen a` instance by building its `unGen` function.
That's what this code is doing.
This last step indeed builds a function `unGen :: QCGen -> Int -> Prop`.

Inside, this generated `unGen` function,
the code takes the random generated input,
passes it to the given generator to generate a value for type `a` named `x`, using `gen`.
This value is then passed into `shriking`.

The goal to test shrinked values if the main values fails the test of the property.
The documentation says that `shrinking` actually `Shrinks the argument to a property if it fails`.

The `shrinking` function creates a [rose tree](https://en.wikipedia.org/wiki/Rose_tree).
The root node contains the result of applying the property to the main generated value.
The children of the root node contains the results of applying the property to shrinked values of the main generated value.
Its grand children are the results of applying the property to the shrinked values of the shrinked values.
And, so on.
The tree building stops when the property succeeds.

Applying a property to a generated value, whether the initial one, or a result of shrinking,
returns a `Testable` instance.
The library then transforms a tree of `Testable` insances into a `Gen Prop` instance.

For each node in the tree contains usually a simple value.
We transform them to `Property`, then to `Gen Prop`, and finally to `Rose Result`.
All of of these transformations are decortaions, or plumbing if you like the name.
We need them only to satisfy type definitions.
Indeed, when we call `unGen` on the `Property` result, the code ignores given arguments
and always returns the result of applying the property
on the generated value used to create the tree.
And same, as we call `unProp` on `Gen Prop` result, we gen `Rose Result` which always contain
the result of applying the property.

We gen a tree `Rose` of `Rose Result` nodes, `Rose (Rose Result)`.
Another function-less, or plumbing, operation converts
`Rose (Rose Result)` into `Rose Result` instance.
And with similar functions, we wrap it into `Gen Prop` that we return at the end.

### Rose Result
An important think to observe here is that `Rose` is defined as `Rose = MkRose a [Rose a]`.
The root node points to the main generated value evaluation.
Each of the children points to its children.
But, as we build the proprety using `joinRose`, the tree transforms into an array.
The array is built following a [depth-first traversal](https://en.wikipedia.org/wiki/Tree_traversal#Depth-first_search) of the tree.

*** Haskell lazy-evaluations avoids building the whole tree here??

The result returned by these evaluation is deconstructed into `MkRose res ts`.
This result is the outcome of the current iteration of the engine.
`res` is the result of the main generated value.
`ts` is the array of children results.

If `res` is a failure, that is if it's `MkResult{ok = Just False}`,
shrinking loop kicks in to find the smallest value that fails to return it.
This values is called a local minimum.
Aside from the output we see in the terminal, the function basically
goes through the children from right to left and tests each element.
If the property succeeds, it checks next elements.
If not, keeps track of the failed result, increments a counter, and continues checking.
It stops when a threshold of attemps is reached or after testing all the results available.

*** How do we get from `Rose Result` to the iteration result ...?
evaluated to produce a `IO (Rose Result)` then`MkRose res ts :: MkRose Result [Rose Result]` then  `Result`.




## PropEr
https://github.com/proper-testing/proper
`PropEr` is the common Erlang property-based testing library.

To use it, we call `quickcheck` with a property and a set of guiding properties:
```erlang
prop_enc_dec() ->
  ?FORALL(
    Msg,
    union([binary(), lists:seq(1, 255)]),
    base64_decode(base64_encode(Msg)) =:= Msg
  ).

proper:quickcheck(prop_enc_dec(), [{numtests,10000}])
```

`prop_enc_dec` is the property. `union([binary(), lists:seq(1, 255)])` is the input generator.
This test fails.
Generated input can be an invalid UTF-8 encoded string.
Some integers in the range between 1 and 255 may not be valid
characters in the Base64 encoding table.
Decoding them fails the check.

### What's inside a property
The property is created with the `?FORALL` [macro](https://en.wikipedia.org/wiki/Macro_(computer_science)).
It creates a property from a variable name, a generator, and a property body.
The property takes the variable in the first argument as its argument.

A property in Erlang is a tuple.
`?FORALL` aboves creates this structure:
```erlang
{forall, union([binary(), ...]), fun(X) -> base64_decode(base64_encode(Msg)) =:= Msg end}.
```
The first element is an atom.
The second is the generator.
The last is a the check, a function that takes the generated input and returns a boolean value.

The definition of a test structure is
```erlang
%% TODO: Should the tags be of the form '$...'?
-opaque test() :: boolean()
	        | {'forall', proper_types:raw_type(), dependent_test()}
	        | {'exists', proper_types:raw_type(), dependent_test(), boolean()}
	        | {'conjunction', [{tag(),test()}]}
	        | {'implies', boolean(), delayed_test()}
	        | {'sample', sample(), stats_printer(), test()}
	        | {'whenfail', side_effects_fun(), delayed_test()}
	        | {'trapexit', fun(() -> boolean())}
	        | {'timeout', time_period(), fun(() -> boolean())}.
```

*** other values than `forall` can be ...?
a function property that returns a `test` instance
```erlang
-type dependent_test() :: fun((proper_gen:instance()) -> test()).
```

a test can return either a boolean or a test structure.
When a test structure is returned, a new testing iteration with the following instances in `Bound`
are cehcked as part of checking a generated instance.

*** targeted generation/testing `-define(FORALL_TARGETED ...  proper:targeted ...` is ...?

`quickcheck` gets a property and a list of options.
Inside, there are two strategies to execute tests.

The options structure contains an attribute, named `numworkers`, that
```erlang
Specifies the number of workers to spawn when performing the tests (defaults to 0).
Each worker gets their own share of the total of number of tests to perform.
```

*** A worker in Erlang is ...?

When the number of worker is specified, PropEr handles pure and impure properties differently.
*** why ??
`property_type` is another attirbute that
```erlang
Declares the type of the property, as in pure with no side-effects or state, and impure with them.
...
In addition, impure properties have each worker spawned on its own node.
```

*** `proper_target` module is ...?
```erlang
%%% @doc This module defines the top-level behaviour for Targeted
%%% Property-Based Testing (TPBT). Using TPBT the input generation
%%% is no longer random, but guided by a search strategy to increase
%%% the probability of finding failing input. For this to work, the user
%%% has to specify a search strategy and also needs to extract
%%% utility values from the system under test that the search strategy
%%% then tries to maximize (or minimize).
```

*** `proper_sa` module / simulated annealing is ...?
```erlang
%%% @doc This module provides simulated annealing (SA) as search strategy
%%% for targeted property-based testing. SA is a local search meta-heuristic
%%% that can be used to address discrete and continuous optimization problems.
%%%
%%% SA starts with a random initial input. It then produces a random input in
%%% the neighborhood of the previous one and compares the fitness of both. If
%%% the new input has a higher fitness than the previous one, it is accepted
%%% as new best input. SA can also accepts worse inputs with a certain
%%% probability.
```

Properties that require more than one worker need a logic that splits the load
and synchronizes the results.
Inside a worker then, the logic is similar to a sequential execution that uses only one worker.

### Sequential tests execution
The logic is defined by `perform`.
This function takes 6 arguments.
These are the test, the total number of tests, the options, the number of passing tests,
the number of tests left, samples, and printers.
It returns the testing result.

Testing result is either the `ok` atom, or
```erlang
-type imm_result() :: #pass{reason :: 'undefined'} | #fail{} | error().
```

The testing ends when this functions gets `0` as the number of remaining tests,
or when the number of passed tries is equal to the number of tries to-pass.

Other than that, `perform` is called recursively, launching a new testing iteration each time.
PropEr calls `run(Test, Opts)` to check the property.
This function returns a `run_result`, which can be either `#pass`, `#fail`, or `error`.

If the testing succeeds, a structure is created:
```erlang
#pass{reason = Reason, samples = lists:reverse(Samples),  printers = lists:reverse(Printers), actions = Actions}.
```

If the input fails to pass the property, a structure is created
```erlang
#fail{reason = Reason, bound = lists:reverse(Bound), actions = lists:reverse(Actions)}.
```
`Bound` is an array
```erlang
-type imm_testcase() :: [imm_input()].
-type imm_input() :: proper_gen:imm_instance() | {'$conjunction',sub_imm_testcases()}.

-type sub_imm_testcases() :: [{tag(),imm_testcase()}].
-type tag() :: atom().

-type imm_instance() :: proper_types:raw_type()
		      | instance()
		      | {'$used', imm_instance(), imm_instance()}
		      | {'$to_part', imm_instance()}.
-type instance() :: term().
-opaque type() :: {'$type', [type_prop()]}.
-type raw_type() :: type() | [raw_type()] | loose_tuple(raw_type()) | term().
-type type_prop() ::
      {'kind', type_kind()}
    | {'generator', proper_gen:generator()}
    | {'reverse_gen', proper_gen:reverse_gen()}
    | {'parts_type', type()}
    | {'combine', proper_gen:combine_fun()}
    | {'alt_gens', proper_gen:alt_gens()}
    | {'shrink_to_parts', boolean()}
    | {'size_transform', fun((proper_gen:size()) -> proper_gen:size())}
    | {'is_instance', instance_test()}
    | {'shrinkers', [proper_shrink:shrinker()]}
    | ...
```

`bound` value we use to create the failure structure is created by `run` function,
it can be `NewCtx = Ctx#ctx{bound = [ImmInstance | Bound]},`.
During the first call, `Bound` is an empty array and `ImmInstance` is the result of `proper_gen:safe_generate(RawType)`.

`Reason` values can be
```erlang
-type fail_reason() :: 'false_prop' | 'time_out' | {'trapped',exc_reason()}
		     | exception() | {'sub_props',[{tag(),fail_reason()},...]}
		     | 'exists' | 'not_found'.
```

When the result is an error, it means that the testing can't continue.
*** The reason can be ...?

After getting this result, `perfom`
decides whether to fail and return an error,
or to start a new iteration.

```erlang
case run(Test, Opts) of
#pass{reason = true_prop, samples = MoreSamples, printers = MorePrinters} ->
    NewSamples = add_samples(MoreSamples, Samples),
    perform(Passed + 1, ToPass, TriesLeft - 1, Test, NewSamples, Printers, Opts);
-- ...
{error, rejected} ->
    perform(Passed, ToPass, TriesLeft - 1, Test, Samples, Printers, Opts);
```

`add_samples` is called when the checking succeeds.
It adds `MoreSample` to the existing `Samples`.
*** Samples are ...?

There are 21 overloaded definition of `run`.
Each variant handles a different kind of test,
a property tuple with a different first element.
It can be `exists`, `forall`, `conjunction`, `implies`, `sample`, `whenfail`, ...
But, we can see some patterns.

If the first element is `forall`, we have 4 definitions.
One generates an input and checks the property.
And, the other three variants are called during shrinking.

The first generates an input intance using
```erlang
proper_gen:safe_generate(RawType)
```
Then, it applies the property to it.
If the result is `true` it returns a `#pass` result.
If it's false, it returns a `#fail` result.

*** what about variants with a head different from `forall` ...?

*** Tests left argument is ...?
The number of tests left is passed as `NumTests * 5` when the number of workers is 0.
Elsewhere, it's `NumTests * 15`.
```erlang
When working on parallelizing PropEr initially we used to hit
too easily the default maximum number of tries that PropEr had,
so when running on parallel it has a higher than usual max
number of tries. The number was picked after testing locally
with different values.
```

### Shrinking
After `perform` finishes its iterations, `test` function executes
```erlang
{ShortResult,LongResult} = get_result(ImmResult, Test, Opts)
```

*** `ShortResult` vs `LongResult` ...?

`get_result` returns `{true, true}` when all the checks passes.
It returs `{false, false}` if checking is interrupted for unexpected reasons,
that is if it returns an `{error, Reason}` tuple or if the `reason` inside `fail` is `not_found`.

If the checks fails, shrinking starts.
`shrink` is called:
```erlang
shrink(Bound, Test, Reason, Opts) 
```
`shrink` is defined as
```erlang
-spec shrink(imm_testcase(), test(), fail_reason(), opts()) -> {'ok',imm_testcase()} | error().
```

Calling `shrink` executes
```erlang
StrTest = skip_to_next(Test)
{Shrinks,MinImmTestCase} = fix_shrink(ImmTestCase, StrTest, Reason, 0, MaxShrinks, Opts)
rerun(Test, true, MinImmTestCase)
```

`skip_to_next` behaves differently for different structures of the test.
It's defined as
```erlang
-spec skip_to_next(test()) -> stripped_test().

-type stripped_test() :: boolean()
		       | {proper_types:type(), dependent_test()}
		       | [{tag(),test()}].
```
If the head is `forall` atom, the result a tuple containing
the proprtey and the type of the proprety function.
Inside, `fix_shrink` gets the property and the input type from this argument.
And, it changes it inside the loop when a minimally shrinked failed value is found
```erlang
Instance = proper_gen:clean_instance(ImmInstance),
NewStrTest = force_skip(Instance, Prop),
```

`rerun` invokes `run` with `mode = try_shrunk` and `bound = MinImmTestCase`, the list of shrinked values.
When the proprety head is `forall`, this means rechecking the proprtey with all the result
of shrinking and returning the result.


`fix_shrink` gets `Bound`, an array of generated inputs,
`StrTest` (see above),
the failure reason from `perfom` result,
the number of shrinks done,
the maximum number of shrinks named `ShrinksLeft`,
and the options structure we pass to `quickcheck` in the first place.
and returns a `shrinking_result`, a tuple containing the nuber of shrinks done and the list of shrinked values.

```erlang

fix_shrink(ImmTestCase, _StrTest, _Reason, Shrinks, 0, _Opts) ->
    {Shrinks, ImmTestCase};
fix_shrink(ImmTestCase, StrTest, Reason, Shrinks, ShrinksLeft, Opts) ->
  case shrink([], ImmTestCase, StrTest, Reason, 0, ShrinksLeft, init, Opts) of
    {0,_MinImmTestCase} ->
        {Shrinks, ImmTestCase};
    {MoreShrinks,MinImmTestCase} ->
        fix_shrink(MinImmTestCase, StrTest, Reason, Shrinks + MoreShrinks, ShrinksLeft - MoreShrinks, Opts)
  end.
```

`fix_shrink` starts a shrinking loop. It calls `shrink`, then either calls itself
recursively with a smaller `ShrinksLeft` value or returns.

`shrik` takes a state as one of its arguments. This is passed as `init` in the first call.
It's of type `proper_shrink:state()`.
```erlang
-type state() :: 'init' | 'done' | {'shrunk',position(),state()} | term().
```
Where do we use each value.
and returns a tuple containing the nuber of shrinks done and the list of shrinked values.


Inside each iteration of this loop,
****ImmInstance = ...?,
gets a list of shrinked values and a new state by calling `proper_shrink:shrink`.
Then, if all shrinked values passes the proprety function, it removes the frist element in of `ImmTestCase`,
which means that the element cannot be shrunked farther, and starts a new iteration.
If a shrinking element fails the check for the same reason, it puts it in the `ImmTestCase` array in place of the target element
and starts another iteration.

```erlang
shrink(Shrunk, TestTail, StrTest, _Reason, Shrinks, ShrinksLeft, _State, _Opts) when is_boolean(StrTest)
					  orelse ShrinksLeft =:= 0
					  orelse TestTail =:= []->
    {Shrinks, lists:reverse(Shrunk, TestTail)};

shrink(Shrunk, [RawImmInstance | Rest] = TestTail, {Type,Prop} = StrTest, Reason, Shrinks, ShrinksLeft, State, Opts) ->
    ImmInstance = case proper_types:find_prop(is_user_nf, Type) of
                    {ok, true} ->
                      case proper_types:safe_is_instance(RawImmInstance, Type) of
                        false ->
                          CleanInstance = proper_gen:clean_instance(RawImmInstance),
                          case proper_types:safe_is_instance(CleanInstance, Type) of
                            true -> CleanInstance;
                            false -> RawImmInstance
                          end;
                        true -> RawImmInstance
                      end;
                    {ok, false} -> RawImmInstance;
                    error -> RawImmInstance
                  end,
    {NewImmInstances,NewState} = proper_shrink:shrink(ImmInstance, Type, State),
    IsValid = fun(I) -> I =/= ImmInstance andalso still_fails(I, Rest, Prop, Reason)  end,
    case proper_arith:find_first(IsValid, NewImmInstances) of
        none ->
            shrink(Shrunk, TestTail, StrTest, Reason, Shrinks, ShrinksLeft, NewState, Opts);
        {Pos, ShrunkImmInstance} ->
            (Opts#opts.output_fun)(".", []),
            shrink(Shrunk, [ShrunkImmInstance | Rest], StrTest, Reason, Shrinks+1, ShrinksLeft-1, {shrunk,Pos,NewState}, Opts)
    end;
still_fails(ImmInstance, TestTail, Prop, OldReason) ->
    Instance = proper_gen:clean_instance(ImmInstance),
    Ctx = #ctx{mode = try_shrunk, bound = TestTail},
    case force(Instance, Prop, Ctx, #opts{}) of
	#fail{reason = NewReason} ->
	    same_fail_reason(OldReason, NewReason);
	_ ->
	    false
    end.

 %% We don't mind if the stacktraces are different.
same_fail_reason({trapped,{ExcReason1,_StackTrace1}},
		 {trapped,{ExcReason2,_StackTrace2}}) ->
    same_exc_reason(ExcReason1, ExcReason2);
same_fail_reason({exception,SameExcKind,ExcReason1,_StackTrace1},
		 {exception,SameExcKind,ExcReason2,_StackTrace2}) ->
    same_exc_reason(ExcReason1, ExcReason2);
same_fail_reason({sub_props,SubReasons1}, {sub_props,SubReasons2}) ->
    length(SubReasons1) =:= length(SubReasons2) andalso
    lists:all(fun({A,B}) -> same_sub_reason(A,B) end,
	      lists:zip(lists:sort(SubReasons1),lists:sort(SubReasons2)));
same_fail_reason(SameReason, SameReason) ->
    true;
same_fail_reason(_, _) ->
    false.
```

*** why do we need these...?
*** `shrink_all` is ...?
```erlang
shrink(Shrunk, [ImmInstance | Rest], {_Type,Prop}, Reason, Shrinks, ShrinksLeft, done, Opts) ->
    Instance = proper_gen:clean_instance(ImmInstance),
    NewStrTest = force_skip(Instance, Prop),
    shrink([ImmInstance | Shrunk], Rest, NewStrTest, Reason, Shrinks, ShrinksLeft, init, Opts);

shrink(Shrunk, [{'$conjunction',SubImmTCs}], SubProps, {sub_props,SubReasons},
       Shrinks, ShrinksLeft, init, Opts) when is_list(SubProps) ->
    shrink_all(Shrunk, [], SubImmTCs, SubProps, SubReasons, Shrinks, ShrinksLeft, Opts).

```

`proper_shrink:shrink` is defined as
```erlang
-spec shrink(proper_gen:imm_instance(), proper_types:type(), state()) ->
	  {[proper_gen:imm_instance()],state()}.

shrink(ImmInstance, Type, init) ->
    Shrinkers = get_shrinkers(Type),
    shrink(ImmInstance, Type, {shrinker,Shrinkers,dummy,init});
shrink(_ImmInstance, _Type, {shrinker,[],_Lookup,init}) ->
    {[], done};
shrink(ImmInstance, Type, {shrinker,[_Shrinker | Rest],_Lookup,done}) ->
    shrink(ImmInstance, Type, {shrinker,Rest,dummy,init});
shrink(ImmInstance, Type, {shrinker,Shrinkers,_Lookup,State}) ->
    [Shrinker | _Rest] = Shrinkers,
    {DirtyImmInstances,NewState} = Shrinker(ImmInstance, Type, State),
    SatisfiesAll =
	fun(I) ->
	    Instance = proper_gen:clean_instance(I),
	    proper_types:weakly(proper_types:satisfies_all(Instance, Type))
	end,
    {NewImmInstances,NewLookup} =
	proper_arith:filter(SatisfiesAll, DirtyImmInstances),
    {NewImmInstances, {shrinker,Shrinkers,NewLookup,NewState}};
shrink(ImmInstance, Type, {shrunk,N,{shrinker,Shrinkers,Lookup,State}}) ->
    ActualN = lists:nth(N, Lookup),
    shrink(ImmInstance, Type,
	   {shrinker,Shrinkers,dummy,{shrunk,ActualN,State}}).
```
It gets a a generated instance, its type, and a state (why?),
and returns a list of instances and a state (the same?).

Internally, it calls `get_shrinkers` to get a list of shriker for the given type.
And, it executes either
```erlang
    [Shrinker | _Rest] = Shrinkers,
    {DirtyImmInstances,NewState} = Shrinker(ImmInstance, Type, State),
    SatisfiesAll =
	fun(I) ->
	    Instance = proper_gen:clean_instance(I),
	    proper_types:weakly(proper_types:satisfies_all(Instance, Type))
	end,
    {NewImmInstances,NewLookup} = proper_arith:filter(SatisfiesAll, DirtyImmInstances),
    {NewImmInstances, {shrinker,Shrinkers,NewLookup,NewState}};
```
when the state in `init` (during the first call), or when the previous iteration
failed to shrink a value further.

Otherwise, when it shrinks the previous value successfully
and adds a shrinked instance (the first one that `satisfyAll`) as a first element in the list,
it executes
```erlang
    ActualN = lists:nth(N, Lookup),
    shrink(ImmInstance, Type,  {shrinker,Shrinkers,dummy,{shrunk,ActualN,State}}).
```
Here, `ImmInstance` is the shrunk value that still fails the proprety.
`N` is position of the first shrinked value that fails the test in the list of shrunked values returned by `proper_shrink:shrink`,
`{shrinker,Shrinkers,Lookup,State}` is the state returned by the `Shrinker` in the previous
call to `proper_shrink`, and it's passed to the next `Shrinker`.

This returns `NewImmInstances`, a list of shrinked instances,
and a new state `{shrinker,Shrinkers,NewLookup,NewState}`.
This new state is passed to `proper:shrink` when it's called recusively
```erlang
    case proper_arith:find_first(IsValid, NewImmInstances) of
	none ->
	    shrink(Shrunk, TestTail, StrTest, Reason,
		   Shrinks, ShrinksLeft, NewState, Opts);
	{Pos, ShrunkImmInstance} ->
	    (Opts#opts.output_fun)(".", []),
	    shrink(Shrunk, [ShrunkImmInstance | Rest], StrTest, Reason,
		   Shrinks+1, ShrinksLeft-1, {shrunk,Pos,NewState}, Opts)
```

Basically, here, we're getting a list of shrinkers,
we try the first shrinker, get a list of values,
find the first one that still fails the test.
If can't find it, move the next failed values.
If we can find it, to shrink it further,
we use the same shrinker, gets a list of more shrinked values,
try them, find the first one that fails and reloop.

`get_shrinkers` takes a type and return a list of shrinker functions.
Shrinkers returned ca nbe either custom or standard.
```erlang
CustomShrinkers =
		case proper_types:find_prop(shrinkers, Type) of
		    {ok, Shrinkers} -> Shrinkers;
		    error           -> []
		end,
	    StandardShrinkers =
		case proper_types:get_prop(kind, Type) of
		    basic ->
			[];
		    wrapper ->
			[fun alternate_shrinker/3, fun unwrap_shrinker/3];
		    constructed ->
			case proper_types:get_prop(shrink_to_parts, Type) of
			    true ->
				[fun to_part_shrinker/3, fun parts_shrinker/3,
				 fun in_shrinker/3];
			    false ->
				[fun parts_shrinker/3, fun in_shrinker/3]
			end;
		    container ->
			[fun split_shrinker/3, fun remove_shrinker/3,
			 fun elements_shrinker/3];
		    _Other ->
			[]
		end,
```

A Shrinker is a function defined as
```erlang
-spec parts_shrinker(proper_gen:imm_instance(), proper_types:type(), state()) ->  {[proper_gen:imm_instance()],state()}.
```

A shrinker returns a `State` `done` when a value cannot be shrinked farther.
In such case, (this happens when the shrinked value is final but succeeds the test, we keep `Shrunk` and `Shrinked` as they are)
 `proper:shrink` starts puts the shrinked element in the `Shrunk` list and moves to the next
```erlang
    Instance = proper_gen:clean_instance(ImmInstance),
    NewStrTest = force_skip(Instance, Prop),
    shrink([ImmInstance | Shrunk], Rest, NewStrTest, Reason,
	   Shrinks, ShrinksLeft, init, Opts);
```

Also in such case, (this happens when the shrinked value is final but fails the test)
`proper_shrink:shrink` starts shrikning with the next shrinker,
until no shrinker is left.
Then, it returns an empty array as a list of instances.
This maker `proper:shrink` to move to shrinking the next failing instance.

*** examples of shrinkers are ...?

*** `mode = try_cexm` is ...?

### Multi-workers execution
`parallel_perfom`.
```erlang
Runs PropEr in parallel mode, through the use of workers to perform the tests.
%% Under this mode, PropEr needs information whether a property is pure or impure,
%% and this information is passed via an option.
%% When testing impure properties, PropEr will start a node for every worker that will be
%% spawned in order to avoid test collisions between them.
```

Inside the `Options` structure passed to the test,
the attributes that matters the most in parallel performance are `property_type`, `strategy_fun`, and `stop_nodes`.

`strategy_fun` is an attribute that
```erlang
%%% <dd> Overrides the default function used to split the load of tests among the workers.
%%% It should be of the type {@link strategy_fun()}.</dd>
```
and
```erlang
%% A function that given a number of tests and a number of workers, splits
%% the load in the form of a list of tuples with the first element as the
%% starting test and the second element as the number of tests to do from there on.
```
*** what it does...?
*** how does it keep track of `Passed`, the number of passing tests...?
`perfom` whith multiple workers sends the result as a message instead of returning it.


The result is returned as a sample function `return` expression if
the number of workers in the options is `0`.
If not, it sends the result as a message to `From` values,
which is the value of `parent` attribute in the options.
`parent` is set to the process that runs the testing. (*** sure ...?)
when testing succeeds, it sends a message to the `parent` attribute with a `#pass` value.

`parallel_perform` , like `perform`, returns an `imm_result` value.
The function that calls `perform` or `parallel_perform` handles the result in the same way.
The return value is the result of calling `spawn_workers_and_get_result`.
This evaluates to
```erlang
spawn_workers_and_get_result(SpawnFun, WorkerArgs) ->
    WorkerList = lists:map(SpawnFun, WorkerArgs),
    InitialResult = #pass{samples = [], printers = [], actions = []},
    AggregatedImmResult = aggregate_imm_result(WorkerList, InitialResult),
```
It calls `SpawnFun` with each `WorkerArgs` argument.
This is diffrent for each of pure and impure functions (see next two sections).
Then, it aggregates the result and returns it.

Inside, `aggregate_imm_result` waits for the results of workers and returns an `imm_result` value.
It's implemented as
```erlang
aggregate_imm_result([], ImmResult) ->
    ImmResult;
aggregate_imm_result(WorkerList, #pass{performed = Passed, samples = Samples} = ImmResult) ->
    Id = get('$property_id'),
    receive
        %% if we haven't received anything yet we use the first pass we get
        {worker_msg, #pass{} = Received, From, Id} when Passed =:= undefined ->
            aggregate_imm_result(WorkerList -- [From], Received);
        %% from that moment on, we accumulate the count of passed tests
        {worker_msg, #pass{performed = PassedRcvd, samples = SamplesRcvd}, From, Id} ->
            NewImmResult = ImmResult#pass{performed = Passed + PassedRcvd,
                                          samples = Samples ++ SamplesRcvd},
            aggregate_imm_result(WorkerList -- [From], NewImmResult);
        {worker_msg, #fail{performed = FailedOn} = Received, From, Id} ->
            lists:foreach(fun(P) ->
                            P ! {worker_msg, {failed_test, self()}, Id}
			  end, WorkerList -- [From]),
            Performed = lists:foldl(fun(Worker, Acc) ->
                                receive
                                    {worker_msg, {performed, undefined, Id}} -> Acc;
                                    {worker_msg, {performed, P, Id}} -> P + Acc;
                                    {worker_msg, #fail{performed = FailedOn2}, Worker, Id} -> FailedOn2 + Acc
                                end
                             end, 0, WorkerList -- [From]),
            kill_workers(WorkerList),
            aggregate_imm_result([], Received#fail{performed = Performed + FailedOn});
```

Here, the function waits a message.
The message comes from a worker, its format is `{worker_msg, Result}`.
`Result` can be `#fail`, `#pass`, or an error tuple.
It adds the result and calls itself recurively to wait for the next message.
When, all the messages are received, it returns.


### When the property is pure
Internally, if the function is pure, `parallel_perform` calls `spawn_workers_and_get_result`,
which in turn spawns a worker?? for each node?? then returns `aggregate_imm_result` result:
```erlang
spawn_workers_and_get_result(SpawnFun, WorkerArgs) ->
    WorkerList = lists:map(SpawnFun, WorkerArgs),
    InitialResult = #pass{samples = [], printers = [], actions = []},
    aggregate_imm_result(WorkerList, InitialResult),
```

`SpawnFun`, with a pure property, is defined as:
```erlang
SpawnFun = fun({Start, ToPass}) ->
              spawn_link_migrate(undefined, fun() -> perform(Start, ToPass, Test, Opts) end)
           end,
```

`spawn_link_migrate` is defined as
```erlang
-spec spawn_link_migrate(node(), fun(() -> 'ok')) -> pid().
```

when its first argument is `undefined`, it just starts a worker to run the function in the second argument.
That is, it executes `spawn_link(Fun)`.

[`spawn_link`](https://www.erlang.org/doc/man/erlang.html#spawn_link-1)
is a function used to create a new process that is linked to the current process.

> Returns the process identifier of a new process started by the application of Fun to the empty list [].
> A link is created between the calling process and the new process, atomically. Otherwise works like spawn/3.


`aggregate_imm_result`is called as `aggregate_imm_result(lists:map(SpawnFun, WorkerArgs), InitialResult)`.
`WorkerArgs` here is `TestsPerWorker`, the number of tests each worker will handle.
It's the result of calling the strategy function.
The first argument is a list of the pids of the spawned workers.


### What if the property is impure
If it's impure, PropEr starts all nodes for workers before starting test execution.
Indeed, it starts the node, runs the tests on them and gets the result, then stops the nodes.


A node/worker here, as opposed to a worker for pure properties,
is a gen stream process and not a worker ??(what's the diff?)


Starting a node:
```erlang

start_link(Info) ->
    gen_statem:start_link({local,?NAME}, ?MODULE, Info, []).

%% @doc Starts a remote node to ensure the testing will not
%% crash the BEAM, and loads on it all the needed code.
-spec start_node(node()) -> node().
start_node(Name) ->
case peer:start_link(#{name => Name}) of
    {ok, Pid, Node} ->
        register(Node, Pid),
        _ = update_worker_node_ref({Node, {already_running, false}}),
        Node;)
    {error, {already_running, Node}} ->
        _ = update_worker_node_ref({Node, {already_running, true}}),
        Node
```

[`start_link`](https://www.erlang.org/doc/man/gen_statem.html#start_link-4)
>  Creates a gen_statem process according to OTP design principles (using proc_lib primitives)
> that is linked to the calling process.
> This is essential when the gen_statem must be part of a supervision tree so it gets
> linked to its supervisor. 


*** `ensure_code_loaded` is ...?

When `spawn_link_migrate` first argument is a `Node`
That is, it executes `spawn_link(Node, Fun)`.
[`spawn_link`](https://www.erlang.org/doc/man/erlang.html#spawn_link-2)
> Returns the process identifier (pid) of a new process started by the application of
> Fun to the empty list [] on Node. A link is created between the calling process and the new process,
> atomically. If Node does not exist, a useless pid is returned and an exit signal with reason
> noconnection is sent to the calling process. Otherwise works like spawn/3.

`SpawnFun`, with an impure property, is defined as:
```erlang
SpawnFun = fun({Node, {Start, ToPass}}) ->
              spawn_link_migrate(Node, fun() -> perform(Start, ToPass, Test, Opts) end)
          end,
```

`SpawnFun`  is defined inside `parallel_perform` and it differs depending on the puriy/impurity
of the property.
It's called for each element in `WorkerArgs`.

### Generation
*** `proper_gen` module is ...?
*** `proper_gen:safe_generate` is ...?
This gives as a value we add to `Bound` array.
To get the input to the property function, we transform it with `proper_gen:clean_instance(ImmInstance)` first.

*** `proper_gen:clean_instance` is ...?

***     apply_args([proper_symb:internal_eval(Arg)], Prop, Ctx, Opts).

*** `-spec spawn_link_migrate(node(), fun(() -> 'ok')) -> pid().` is ...?
*** HHERE?
