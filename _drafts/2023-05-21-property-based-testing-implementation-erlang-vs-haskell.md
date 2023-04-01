---
layout:   post
comments: true
title:    "Property-based testing implementation: Erlang vs Haskell"
date:     2022-05-21 12:02:00 +0100
tags:     featured
---

Property-based testing is ...
You can reade about it here...

Both [Haskell]() and [Erlang]() are functional languages...

## Quickcheck
https://github.com/nick8325/quickcheck
Quickchek is a Haskell property-based testing library.
https://begriffs.com/posts/2017-01-14-design-use-quickcheck.html

* Give simple example and anlyze what happens
```haskell
prop_reverse :: [Int] -> Bool
prop_reverse xs = reverse (reverse xs) == xs

>>> quickCheck (withMaxSuccess 10000 prop_reverse)
+++ OK, passed 10000 tests.
```
* engine
The engine that runs the tests in managed by `test :: State -> Property -> IO Result`.
`property` is the check, `prop_reverse` above.
`state` is/contains ...?

*** This `test` is called recursively.
Each time, it checks the property with an input, and calls itself with a next state.
This continues until no testing should is needed,
that is when
`numSuccessTests st   >= maxSuccessTests st && isNothing (coverageConfidence st)`
*** Test.hs/test/doneTesting??
or when
`numDiscardedTests st >= maxDiscardedRatio st * max (numSuccessTests st) (maxSuccessTests st)`.
*** Test.hs/test/giveUp??
Internally, each iteration in the loop tests the property, creates a next state,
then decides whether to run another loop etration or to stop.

*** `test` signature is `test :: State -> Property -> IO Result`
We call `quickCheck` to start testing and pass in a prorpety we want to check
```haskell
quickCheck :: Testable prop => prop -> IO ()
quickCheck p = quickCheckWith stdArgs p
```
`Testable` is a Haskell class:
```haskell
-- | The class of properties, i.e., types which QuickCheck knows how to test.
-- Typically a property will be a function returning 'Bool' or 'Property'.
--
-- If a property does no quantification, i.e. has no
-- parameters and doesn't use 'forAll', it will only be tested once.
-- This may not be what you want if your property is an @IO Bool@.
-- You can change this behaviour using the 'again' combinator.
class Testable prop where
  -- | Convert the thing to a property.
  property :: prop -> Property
```
we instanciate this class for certain types
```haskell
instance Testable Bool where
  property = property . liftBool

instance Testable Result where
  property = MkProperty . return . MkProp . protectResults . return
  ...
```
`Property` is value of this class
It can be
```haskell
prop_cyclic :: Property
prop_cyclic =
  forAll (Blind <$> cyclicList) $ \(Blind xs) ->
    -- repeats with period 2
    and $ take 100 $ zipWith (==) xs (drop 2 xs)
```
`Property` is `Testable`, we have
```haskell
instance Testable Property where
  property (MkProperty mp) = MkProperty (fmap protectProp mp)
```
`State` is ...?

*** The result returned by the loop in the end is either
`Success` A successful test run. create by doneTesting,
`GaveUp` Given up create by ,
`Failure` A failed test run,
or `NoExpectedFailure` A property that should have failed did not.

*** Each `test`-loop iteration builds a new state.
In order to run another iteration, these condition should be true about the state:
 - should be false: `numSuccessTests st   >= maxSuccessTests st && isNothing (coverageConfidence st)`
 - should be false: `numDiscardedTests st >= maxDiscardedRatio st * max (numSuccessTests st) (maxSuccessTests st)`
 - failed test: res=`MkResult{ok = Just False}` and `(numShrinks, totFailed, lastFailed, res) <- foundFailure st' res ts`;`theOutput <- terminalOutput (terminal st')`;`if not (expect res)`
 - failed test: res=`MkResult{ok = Just False}` and `(numShrinks, totFailed, lastFailed, res) <- foundFailure st' res ts`;`theOutput <- terminalOutput (terminal st')`; and false `if not (expect res)`

*** how state changes between iterations?

*** The check of the property in an iteration is `res` is calculated by
`(unProp (unGen (unProperty f_or_cov) rnd1 size))`
This expression evaluates to `Rose Result`,
which is then evaluated to produce a `IO (Rose Result)` first, `MkRose res ts :: MkRose Result [Rose Result]` and then further evaluated to a `Result` value.
`Rose` is
`data Rose a = MkRose a [Rose a] | IORose (IO (Rose a))`.

Here first `unProperty f_or_cov` gets a value of `Gen Prop` from a value `Property`.
`Property` is defined as
```haskell
newtype Property = MkProperty { unProperty :: Gen Prop }
  deriving (Typeable)
```
This means that a given property should provied implement a funciton `unProperty` that creates a `Gen Prop` value.
As explained above, to transform a `Bool` value to a `Property` value with `unProperty`,
the library instanciates
```haskell
succeeded, failed, rejected :: Result
(succeeded, failed, rejected) =
  (result{ ok = Just True },
   result{ ok = Just False },
   result{ ok = Nothing })
  where
    result =
      MkResult
      { ok                 = undefined
      , expect             = True
      // ...
      }
// ...
liftBool :: Bool -> Result
liftBool True = succeeded
liftBool False = failed { reason = "Falsified" }
// ...
instance Testable Bool where
  property = property . liftBool
```
For value like `forAll` above, we have
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
`again` here converst a `Testable prop` to a `Property`, wihch is have `unProperty:: Gen Prop`.
the second and third definitions means that if we a `Prop` value,
then we'll have first a `Testable Prop`, and then a `Testable (Gen Prop)` value.
This value is created with `property` call, and have a `unProperty` function.
The trick to convert `prop`, not `Prop` with big `P`, value to a `Gen Prop` is in the most-first definiton,
exactly in the `fmap`:
`fmap` for `Gen` is defined as follows:
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

So after all, it's the `Gen` monad that converts a `Prop` value to a `Gen Prop` value.
After this, the other is just glue code to do basic mapping.
And it's here 
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

For example, if
```haskell
f_or_cov = prop_cyclic

cyclicList :: Gen [Int]
cyclicList = do
  rec xs <- fmap (:ys) arbitrary
      ys <- fmap (:xs) arbitrary
  return xs

newtype Blind a = Blind {getBlind :: a}

prop_cyclic :: Property
prop_cyclic =
  forAll (Blind <$> cyclicList) $ \(Blind xs) -> and $ take 100 $ zipWith (==) xs (drop 2 xs)
```

`unProperty f_or_cov` gives `Gen Prop` instance.
we have
```haskell
forAll :: (Show a, Testable prop)
       => Gen a -> (a -> prop) -> Property
forAll gen pf = forAllShrink gen (\_ -> []) pf
```

*** how to get from `f_or_cov::Property` to `Rose Result`

*** how to get from there to `MkRose res ts`, protectRose . reduceRose ::  Rose Result -> IO (Rose Result)

*** how to get from there to `res :: Result`


*** definitions
```haskell
////
(rnd1,rnd2) = split (randomSeed st)

////
let size = (computeSize st) (numSuccessTests st) (numRecentlyDiscardedTests st)

////
newtype Prop = MkProp{ unProp :: Rose Result }

////


////
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
```


**** how state is updated, what changes?: `let st' = st{ covera...`
*** why do we need to call addCoverageCheck in runATest/f_or_cov?

* generation internals
* shrinking internals
* result/report creation


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

## PropEr
https://github.com/proper-testing/proper
PropEr is an Erlang property-based testing library.
