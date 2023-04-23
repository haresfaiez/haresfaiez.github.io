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










## Annex
*** `unGen` from `gen`, `shriker` is ...?
After doing some inlining, we get the definition of this `unGen` function:
```haskell
-- gen :: Gen (b, a) / shrinker :: (b, a) -> [(b, a)] / f :: (b, a) -> prop, m :: QCGen -> Int -> (b, a) / initiallyGenerated :: (b, a)
unGen r n =
  let initiallyGenerated = m r1 n
  in
    case split r of
      (r1, r2) ->
        let MkGen m' = unProperty
                            $ shrinking shrinker initiallyGenerated (\x -> foldr counterexample (property (f x)) (shw x))
        in m' r2 n
```
First, we split the random number generator `r` into `r1` and `r2`.
Then, we apply the function from the function input generator with `r1` and `n`.
Then, we apply `shrinking` to create a `Property` instance.
We unwrap it and get a `Gen Prop` instance.
We use this last to compute the result.
We apply this function with `r2` and `n` to get the final result.
It takes a `shrinker` as a first argument.
This is a function that takes a value and tries to build smaller values.
For example, a shrinker for an array input tries to remove some elements for the array.
The second argument is the actual value we will test.
It's generated by `m r n` in the previously.
The third argument is the property itself.

*** `property` is ...?
We'll study how this instance is created so that we understand what unfolding it means.
After inlining calling functions, we get:
```haskell
property f =
  -- gen :: Gen (b, a) / shrinker :: (b, a) -> [(b, a)] / f :: (b, a) -> prop
  again
    $ MkProperty
      $ gen >>=
           \x -> unProperty
                   $ shrinking shrinker x (\x -> foldr counterexample (property (f x)) (shw x))
```
`again` sets `abort` to `False` in the result structure.
`MkProperty` creates a `Property` instance from a `Gen Prop` intance.
?? And we set `abort` to `False` so that we execute in the next iteration maybe.?
`Gen`?{{{
  `again` here converst a `Testable prop` to a `Property`, wihch is have `unProperty:: Gen Prop`.
  the second and third definitions means that if we a `Prop` value,
  then we'll have first a `Testable Prop`, and then a `Testable (Gen Prop)` value.
  This value is created with `property` call, and have a `unProperty` function.
  The trick to convert `prop`, not `Prop` with big `P`, value to a `Gen Prop` is in the most-first definiton,
  exactly in the `fmap`:
  ```haskell
  fmap :: Functor f => (a -> b) -> f a -> f b
  ```
  here `f` is `Gen`, `a` is `Prop`, and `b` is `Prop` to.
  `(a -> b)` is `f` above, a function that sets `abort` to `False`.
  Implementing the `fmap` is the responisiblity of the `Gen` definer.
  ```haskell
  instance Functor Gen where
    fmap f (MkGen h) =
      MkGen (\r n -> f (h r n))
  ```
  In `mapProp`, `unProperty . property` coneverts a property of `prop :: Testable` to `Gen Prop`.
  `property` converts `prop :: Testable` to `Property` (see the last definition)
  `unProperty` converts this to `Gen Prop`.

  Everything that hsould be tested should be converted first to a `Gen Prop`.
  That said, the `Prop` we get and convert to `Gen Prop`.
  This is done in the second definition above, mainly with `return . protectProp $ p`.
  `p` is the `Prop`, `protectProp` is `protectProp :: Prop -> Prop`.
  `return` indeed is `return :: Prop -> Gen Prop`,
  or technically `return :: Monad m => a -> m a`.
  The monad is `Gen`.
}}}

**** Inline `prop_cyclic` definition further:
```haskell
prop_cyclic :: Property
prop_cyclic =
  again $
    MkProperty $
    (Blind <$> cyclicList) >>= \x ->
      unProperty $
      shrinking 
        (\_ -> [])
        x
        (\y ->
          counterexample
          (show y) 
          ((\(Blind xs) -> and $ take 100 $ zipWith (==) xs (drop 2 xs))
            y)
        )
```
which means
```haskell
-- | Randomly generates a function of type @'Gen' a -> a@, which
-- you can then use to evaluate generators. Mostly useful in
-- implementing 'promote'.
delay :: Gen (Gen a -> a)
delay = MkGen (\r n g -> unGen g r n)

-- | Promotes a monadic generator to a generator of monadic values.
promote :: Monad m => m (Gen a) -> Gen (m a)
promote m = do -- m :: Rose (Gen (??Prop))
  eval <- delay -- eval :: Rose (Gen (??Prop)) -> Rose (??Prop)
  return (liftM eval m) -- eval :: (a1 -> r), m :: m a1, liftM :: (a1 -> r) -> m a1 -> m r
  -- Rose (Gen (??Prop)) -> Gen (Rose (??Prop))

-- ...

-- | Adds the given string to the counterexample if the property fails.
counterexample :: Testable prop => String -> prop -> Property
counterexample s = -- s : String
  let a = MkProperty
   . fmap (
      \(MkProp t) -> 
          MkProp (fmap (\res -> res{ testCase = s:testCase res }) t) -- functor = Rose, f :: Result -> Result
      ) -- functor = Gen, f :: Prop -> Prop, t :: Rose Result
   . unProperty
   . property
  in
    a .
    callback (PostFinalFailure Counterexample $ \st _res -> do
      s <- showCounterexample s
      putLine (terminal st) s)

-- ...

(:) :: a -> [a] -> [a]

---- ME: generates an array with period=2
cyclicList :: Gen [Int]
cyclicList = do
  rec xs <- fmap (:ys) arbitrary --- fmap (Int -> [Int]) (Gen Int) :: Gen [Int]
      ys <- fmap (:xs) arbitrary --- fmap (Int -> [Int]) (Gen Int) :: Gen [Int]
  return xs -- xs :: [Int]

cyclicList = do
  (xs, ys) <- mfix (
    \ ~(xs, ys) -> -- :: ([Int], [Int])
       do {
         xs <- fmap (:ys) arbitrary ; --- :: Gen [Int]
         ys <- fmap (:xs) arbitrary ; --- :: Gen [Int]
         return (xs, ys)
       }
    ) --- :: Gen ([Int], [Int])
  return xs
//...
mfix :: (a -> m a) -> m a
mfix :: (([Int], [Int]) -> Gen ([Int], [Int])) -> Gen ([Int], [Int])

-- ...

prop_cyclic :: Property
prop_cyclic =
  let a = (
      MkProperty
      . fmap (
            mapProp (
                \(MkProp t) -> MkProp (
                    fmap (\res -> res{ abort = False }) t -- Rose Result / functor = Rose / f :: Result -> Result
                  ) -- t :: Rose Result
              ) -- Prop -> Prop
          ) -- Gen Prop / functor = Gen / f :: Prop -> Prop / :: Sets abort to False in the Result inside. The Result is inside Rose, which is inside Prop, that is inside Gen. 
      . unProperty -- Gen Prop
      . property -- Property
    ) -- :: Sets abort to False in the Result inside, and wrap again.


    pf y = -- y :: Blind (Gen [Int])
      counterexample
        (show y) -- String
        ( (\(Blind xs) -> and $ take 100 $ zipWith (==) xs (drop 2 xs)) y ) -- Bool / y :: Blind (Gen [Int]) -> Bool / True if
      --- Property (or is it Gen Property ?)

    props y = MkRose 
      ((unProperty . property . pf) y) [ props x' | x' <- [] ] -- Gen Prop === Gen (MkProp (Rose Result)) // - \x -> [] is shrinker :: a -> [a]
     -- Rose (Gen ??Prop) === MkRose a [Rose a] | IORose (IO (Rose a))
     -- y :: Blind (Gen [Int]) -> Rose (Gen (??Prop))

    shrk x = MkProperty (
        fmap
          (MkProp . joinRose . fmap unProp) -- Prop -> Prop
          (promote
              (props x) -- ??Rose (Gen (??Result)) <<< Rose (Gen (??Prop))
            ) -- Gen Prop === (Gen (Rose (??Result))) <<< Gen (??(Rose Result)) <<< Gen (Rose (??(Rose Result))) <<< Gen (Rose (??Prop))
          -- Gen Prop / functor = Gen / f = Prop -> Prop
      ) -- Property
       

  in
    a (
      MkProperty (
        (fmap Blind cyclicList) -- Gen (Blind (Gen [Int]))
            >>= (\x -> unProperty (shrk x)) -- :: (Blind (Gen [Int])) -> Gen Prop
        -- Gen Prop
      ) -- Property
    )
```

*** why do we need `Blind`
For example here
```haskell
prop_failingTestCase :: Blind (Int -> Int -> Int -> Bool) -> Property
prop_failingTestCase (Blind p) = ioProperty $ do
  res <- quickCheckWithResult stdArgs{chatty = False} p
  let [x, y, z] = failingTestCase res
  return (not (p (read x) (read y) (read z)))
```

*** `Gen` definition
```haskell
-- | A generator for values of type @a@.
--
-- The third-party packages
-- <http://hackage.haskell.org/package/QuickCheck-GenT QuickCheck-GenT>
-- and
-- <http://hackage.haskell.org/package/quickcheck-transformer quickcheck-transformer>
-- provide monad transformer versions of @Gen@.
newtype Gen a = MkGen{
  unGen :: QCGen -> Int -> a -- ^ Run the generator on a particular seed.
                             -- If you just want to get a random value out, consider using 'generate'.
  }
//...
instance Applicative Gen where
  pure x =
    MkGen (\_ _ -> x)
  (<*>) = ap
//...
instance Monad Gen where
  return = pure

  MkGen m >>= k =
    MkGen (\r n ->
      case split r of
        (r1, r2) ->
          let MkGen m' = k (m r1 n)
          in m' r2 n
    )

  (>>) = (*>)
```

*** `localMin` definition
Here's a simplified version of the loop
```haskell
localMin :: State -> P.Result -> [Rose P.Result] -> IO (Int, Int, Int, P.Result)
localMin st res ts = do
  ts' <- tryEvaluate ts
  localMin' st res (either (\_ -> []) id ts')

localMin' :: State -> P.Result -> [Rose P.Result] -> IO (Int, Int, Int, P.Result)
localMin' st res [] = localMinFound st res
localMin' st res (t:ts) = do
  MkRose res' ts' <- protectRose (reduceRose t)
  res' <- callbackPostTest st res'
  let st' = if ok res' == Just False
              then st { numSuccessShrinks = numSuccessShrinks st + 1, numTryShrinks = 0 }
              else st { numTryShrinks = numTryShrinks st + 1, numTotTryShrinks = numTotTryShrinks st + 1 }
  localMin st' res' ts
```

*** `shrinking` definition
```haskell
shrinking shrinker x0 pf = MkProperty (
    fmap :: (Rose Prop -> Prop) -> Gen (Rose Prop) -> Gen Prop
                fmap :: (Prop -> Rose Result) -> Rose Prop -> Rose (Rose Result)
                joinRose :: Rose Rose Result -> Rose Result
    fmap (MkProp . joinRose . fmap unProp) (promote (props x0))
  )
 where
  props :: a -> Rose (Gen Prop)
  props x =
    MkRose (unProperty (property (pf x))) [ props x' | x' <- shrinker x ]
```

*** `forAll` definition helpers
```haskell
mapProp :: Testable prop => (Prop -> Prop) -> prop -> Property
mapProp f = MkProperty . fmap f . unProperty . property
//...
-- f here mustn't throw an exception (rose tree invariant).
mapRoseResult :: Testable prop => (Rose Result -> Rose Result) -> prop -> Property
mapRoseResult f = mapProp (\(MkProp t) -> MkProp (f t))
//...
mapTotalResult :: Testable prop => (Result -> Result) -> prop -> Property
mapTotalResult f = mapRoseResult (fmap f)
//...
-- | Modifies a property so that it will be tested repeatedly.
-- Opposite of 'once'.
again :: Testable prop => prop -> Property
again = mapTotalResult (\res -> res{ abort = False })
//...
instance Testable Result where
  property = MkProperty . return . MkProp . protectResults . return

instance Testable Prop where
  property p = MkProperty . return . protectProp $ p

instance Testable prop => Testable (Gen prop) where
  property mp = MkProperty $ do p <- mp; unProperty (again p)

instance Testable Property where
  property (MkProperty mp) = MkProperty (fmap protectProp mp)
```

*** exception handling??
```
-- The story for exception handling:
--
-- To avoid insanity, we have rules about which terms can throw
-- exceptions when we evaluate them:
--   * A rose tree must evaluate to WHNF without throwing an exception
--   * The 'ok' component of a Result must evaluate to Just True or
--     Just False or Nothing rather than raise an exception
--   * IORose _ must never throw an exception when executed
--
-- Both rose trees and Results may loop when we evaluate them, though,
-- so we have to be careful not to force them unnecessarily.
--
-- We also have to be careful when we use fmap or >>= in the Rose
-- monad that the function we supply is total, or else use
-- protectResults afterwards to install exception handlers. The
-- mapResult function on Properties installs an exception handler for
-- us, though.
--
-- Of course, the user is free to write "error "ha ha" :: Result" if
-- they feel like it. We have to make sure that any user-supplied Rose
-- Results or Results get wrapped in exception handlers, which we do by:
--   * Making the 'property' function install an exception handler
--     round its argument. This function always gets called in the
--     right places, because all our Property-accepting functions are
--     actually polymorphic over the Testable class so they have to
--     call 'property'.
--   * Installing an exception handler round a Result before we put it
--     in a rose tree (the only place Results can end up).
```

*** `Testable` for a `function` is ...?
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
      --- === Testable (b, a)/propertyForAllShrinkShow

class Testable prop where
  propertyForAllShrinkShow :: Gen a -> (a -> [a]) -> (a -> [String]) -> (a -> prop) -> Property
  propertyForAllShrinkShow gen shr shw f =
    forAllShrinkBlind gen shr $ \x -> foldr counterexample (property (f x)) (shw x)


liftM2 :: (b -> a -> (b, a)) -> Gen b -> Gen a =--> Gen (b, a)
liftShrink2 :: (b -> [b]) -> (a -> [a])        =--> (b, a) -> [(b, a)] 
uncurry :: (b -> a -> prop)                    =--> (b, a) -> prop --- (b, a) === f b a



property f =
  -- gen :: Gen (b, a) / shrinker :: (b, a) -> [(b, a)] / f :: (b, a) -> prop
  again
    $ MkProperty
      $ MkGen (\r n ->
              case split r of
                (r1, r2) ->
                  let MkGen m' = unProperty
                                      $ shrinking shrinker (m r1 n) (\x -> foldr counterexample (property (f x)) (shw x))
                  in m' r2 n
            ) --- m === ungen :: QCGen -> Int -> Prop === deconstruction of (gen = MkGen Prop)
```
