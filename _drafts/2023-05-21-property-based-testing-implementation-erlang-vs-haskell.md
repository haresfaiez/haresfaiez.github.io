---
layout:   post
comments: true
title:    "Property-based testing implementation: Erlang vs Haskell"
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
PropEr is an Erlang property-based testing library.

An example or usage is:
```erlang
prop_enc_dec() ->
  ?FORALL(Msg, union([binary(), lists:seq(1, 255)]),
    base64_decode(base64_encode(Msg)) =:= Msg
  ).

proper:quickcheck(prop_enc_dec(), [{numtests,10000}])
```

This property will fails as the check is false.
For example, some binary data may not be valid UTF-8 encoded strings
and could cause encoding errors.
Similarly, some integers in the range 1 to 255 may not be valid
characters in the Base64 encoding table and could cause decoding errors.

The test, or the property if we prefere to hold on the name,
isi created with `?FORALL` in the example.
`FORALL` is a macro that creates a property taking a variable name,
a generator, and a property body.
The property uses the variable defined by the first argument.
It's defined by
```erlang
-define(FORALL(X,RawType,Prop), proper:forall(RawType, fun(X) -> Prop end)).
```

Indeed, a property structure in Erlang is a tuple.
`proper:forall`, for example, is defined as
```erlang
forall(RawType, DTest) -> {forall, RawType, DTest}.
```

*** other values than `forall` can be ...?


*** targeted generation/testing `-define(FORALL_TARGETED ...  proper:targeted ...` is ...?

`quickcheck` takes a property and a list of options as input.
Inside, it calls `test` function, which clean up the global states,
initialize state variables,
calls `inner_test`, then clean up the state again.

*** `setup_test`, `finalize_test` are ...?
*** how does the global attributes change over time...?

*** `cook_test` is ...?

The options contains an attribute `numworkers`.
```erlang
%%% <dd> Specifies the number of workers to spawn when performing the tests (defaults to 0).
%%% Each worker gets their own share of the total of number of tests to perform.</dd>
```
`inner_test` normalizes the porperty then depending on this property,
it either calls `perform` directly when the number of workes is zero,
or it calls `parallel_perfom`.
The latter
```erlang
Runs PropEr in parallel mode, through the use of workers to perform the tests.
%% Under this mode, PropEr needs information whether a property is pure or impure,
%% and this information is passed via an option.
%% When testing impure properties, PropEr will start a node for every worker that will be
%% spawned in order to avoid test collisions between them.
```

`parallel_perform` handles pure properties differently than impure ones.
The attributes that matters the most in parallel performance are `property_type`, `strategy_fun`, and `stop_nodes`.
`property_type` is an attirbute that
```erlang
%%% <dd> Declares the type of the property, as in pure with no side-effects or state,
%%% and impure with them. <b>Notice</b>: this option will only be taken into account if
%%% the number of workers set is greater than 0. In addition, <i>impure</i> properties
%%% have each worker spawned on its own node.</dd>
```

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

`stop_nodes` is an attribute that
```erlang
%%% <dd> Specifies whether parallel PropEr should stop the nodes after running a property
%%% or not. Defaults to true.</dd>
```

Internally, if the function is pure, `parallel_perform` calls `spawn_workers_and_get_result`,
which in turn spawns a worker?? for each node?? then returns `aggregate_imm_result` result:
```erlang
spawn_workers_and_get_result(SpawnFun, WorkerArgs) ->
    WorkerList = lists:map(SpawnFun, WorkerArgs),
    InitialResult = #pass{samples = [], printers = [], actions = []},
    aggregate_imm_result(WorkerList, InitialResult),
```

If it's impure, it also calls `start_nodes` and `ensure_code_loaded` in the beginning,
and `stop_nodes` at the end.
*** These three functions ...?

This function takes two arguments, a spawning function and a list of workers.
`WorkerArgs` is either `StrategyFun(NumTests, NumWorkers)` when the function is pure,
or `lists:zip(start_nodes(NumWorkers), StrategyFun(NumTests, NumWorkers))` when it's not.
Both, evaluations are based on the invokation of `StrategyFun` with the number of tests(it`s ...??)
and the number of workers. Both values are taken from the options.
*** `start_nodes` ...?
*** The result of these evaluations are ...?

`SpawnFun` is defined inside `parallel_perform` and it differs depending on the puriy/impurity
of the property.
It's called for each element in `WorkerArgs`.
With a pure property, it's defined as:
```erlang
SpawnFun = fun({Start, ToPass}) ->
              spawn_link_migrate(undefined, fun() -> perform(Start, ToPass, Test, Opts) end)
           end,
```

With an impure property, it's defined as:
```erlang
SpawnFun = fun({Node, {Start, ToPass}}) ->
              spawn_link_migrate(Node, fun() -> perform(Start, ToPass, Test, Opts) end)
          end,
```

In both cases, it calls `spawn_link_migrate`. Either with a node when the property is impure,
or without, putting `undefined` instead, when it's pure.
*** `spawn_link_migrate` creates a new process ...?

*** `aggregate_imm_result` is ...?

*** `maybe_stop_cover_server` and `maybe_start_cover_server` are ...?

We encountered `perform` invokation twice until now.
One, when the number of workers is zero. `inner_test` calls it.
Then, when inside `parallel_perform`.
The first invokation passes in only the test, the total number of tests, and the options.
The second passes also the number of passing tests.
This number is returned by the strategy functions.
In the first call it's passed further as `0`.

`perform` is defined with varying number of arguments.
The core definition takes 5 arguments.
In addition to these we talked about above, it takes the number of tests left,
samples, and printers.

The number of tests left is passed as `NumTests * 5` in the first call,
when the number of workers is 0.
In the second, it's `NumTests * 15`.
Indeed,
```erlang
%% When working on parallelizing PropEr initially we used to hit
%% too easily the default maximum number of tries that PropEr had,
%% so when running on parallel it has a higher than usual max
%% number of tries. The number was picked after testing locally
%% with different values.
```

Here there are three cases to handle.
When the number of remaining tries is `0`, when `TriesLeft` is `0`,
it either returns `{error, cant_satisfy}` or `#pass{...`.
The result is returned as a sample function `return` expression if
the number of workers in the options is `0`.
If not, it sends the result as a message to `From` values,
which is the value of `parent` attribute in the options.
`parent` is set to the process that runs the testing. (*** sure ...?)

The next case is when the number of passed tries is equal to the number
of tries to-pass.
Here, it usually means the testing succeeded.
If the number of workers is `0`, it returns a `#pass{...`value.
If not, it sends a message to the `parent` attribute with a `#pass{...` value.
*** why calling `check_if_early_fail`...?

The third case is when none of the previous conditions are met.
Here, the property is checked.
Both, when the number of workers is `0` or not, `run(Test, Opts)` is called first.
We'll talk about `run` below.
For now, let's assume it takes a test and a set of options, and returns
a run-result, which is defined as
```erlang
-type run_result() :: #pass{performed :: 'undefined'}
		    | #fail{performed :: 'undefined'}
		    | error().
```

According to the result of running the test, the function either
fails, it returns an error or it sends it to the parent process.
Or, if the result is either `#pass{...` or `{error, rejected}`,
reduces `TriesLeft` and calls `perform` recursively again.

If the check pasess, it also increases `Passed` during the call,
and `add_samples`.

*** `add_samples` is ...?

`run` takes a test, options, and optionally a context.
There are 21 variant where each variant handles a different kind of test.
Specifically, the first element in the test tuple.
It's either `exists`, `forall`, `conjunction`, `implies`, `sample`, `whenfail`, ...
Different definitions handle different values.

*** `run` does ...?


*** `Printers` are ...?
*** what about `printers = MorePrinters` ...?

*** `report_imm_result` and `get_result` are ...?

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

## Annex
```erlang
parallel_perform(Test, #opts{property_type = pure, numtests = NumTests,
                             numworkers = NumWorkers, strategy_fun = StrategyFun} = Opts) ->
    SpawnFun = fun({Start, ToPass}) ->
                  spawn_link_migrate(undefined, fun() -> perform(Start, ToPass, Test, Opts) end)
               end,
    TestsPerWorker = StrategyFun(NumTests, NumWorkers),
    spawn_workers_and_get_result(SpawnFun, TestsPerWorker);
parallel_perform(Test, #opts{property_type = impure, numtests = NumTests,
                             numworkers = NumWorkers, strategy_fun = StrategyFun,
                             stop_nodes = StopNodes} = Opts) ->
    TestsPerWorker = StrategyFun(NumTests, NumWorkers),
    Nodes = start_nodes(NumWorkers),
    ensure_code_loaded(Nodes),
    NodeList = lists:zip(Nodes, TestsPerWorker),
    SpawnFun = fun({Node, {Start, ToPass}}) ->
                  spawn_link_migrate(Node, fun() -> perform(Start, ToPass, Test, Opts) end)
               end,
    AggregatedImmResult = spawn_workers_and_get_result(SpawnFun, NodeList),
    ok = case StopNodes of
        true -> stop_nodes();
        false -> ok
    end,
    AggregatedImmResult.

inner_test(RawTest, Opts) ->
    #opts{numtests = NumTests, long_result = Long,
            numworkers = NumWorkers} = Opts,
    Test = cook_test(RawTest, Opts),
    ImmResult = case NumWorkers > 0 of
    true ->
          Opts1 = case NumWorkers > NumTests of
              true -> Opts#opts{numworkers = NumTests};
              false -> Opts
          end,
          parallel_perform(Test, Opts1);
    false ->
        perform(NumTests, Test, Opts)
    end,
      report_imm_result(ImmResult, Opts),
      {ShortResult,LongResult} = get_result(ImmResult, Test, Opts),
      case Long of
        true  -> LongResult;
        false -> ShortResult
  end.

test(RawTest, Opts) ->
    global_state_init(Opts),
    Finalizers = setup_test(Opts),
    Result = inner_test(RawTest, Opts),
    ok = finalize_test(Finalizers),
    global_state_erase(),
    Result.

quickcheck(OuterTest, UserOpts) ->
  ImmOpts = parse_opts(UserOpts)
  {Test,Opts} = peel_test(OuterTest, ImmOpts),
  test({test,Test}, Opts)
  end.

global_state_init(#opts{start_size = StartSize, constraint_tries = CTries,
			search_strategy = Strategy, search_steps = SearchSteps,
			any_type = AnyType, seed = Seed, numworkers = NumWorkers} = Opts) ->
    clean_garbage(),
    grow_size(Opts),
    proper_arith:rand_restart(Seed),
    proper_typeserver:restart(),
    ok.

global_state_erase() ->
    proper_typeserver:stop(),
    proper_arith:rand_stop(),
    ok.
```
