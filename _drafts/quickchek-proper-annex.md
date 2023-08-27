## How is the output generated
When a property fails, we'll get:

```console
{"elephant"->1, "snake"->1, _->0}
```

This describes a function represented by a structure `Fun String Integer.

We can split this out into two parts.
One with the examples and one with the underscore.

The value of the underscore is the second element of the first argument of `Fun`.
It's the shrinked value of the output type.
It's the return value of the reified version of a `Nil` function structure.

The first part is created with a function named `table`.
In our example, `table` will return:
```haskell
[("elephant", 1), ("snake", 1)]
```

The library uses `table` to get the list of input/output pairs
from a value of a function structure `a :-> b`:
```haskell
table :: (a :-> c) -> [(a,c)]
table (Pair p)    = [ ((x,y),c) | (x,q) <- table p, (y,c) <- table q ]
table (p :+: q)   = [ (Left x, c) | (x,c) <- table p ]
                 ++ [ (Right y,c) | (y,c) <- table q ]
table (Unit c)    = [ ((), c) ]
table Nil         = []
table (Table xys) = xys
table (Map _ h p) = [ (h x, c) | (x,c) <- table p ]
```

Same as `abstract`, `table` reifies the function structure.
But, it produces a list of argument/result pairs
instead of a function.
You can go back to study the structure of the function `String :-> Integer`
we end up with and see how both strings `"elephant"` and `"snake"`
and their return value are created.

Keep in mind that the return value for an each is the return
of the leaf, which is a function that accepts the characters
of the string one by one, joins them to build a string, and calls the
generated function with this string.

If we call `table` and do this with the generated `String :-> Integer`,
we'll have an infinity of values in the result of `table`.
Indeed, `table` will continue unfolding the structure which is itself
infinite (it's composed from tables that contains tables that contains tables ....).

`f` is the generated function `String -> Integer.
** It shows/prints only the pathes that have been already evaluated
*** how is only the evaluated exists in the concrete function ...?
*** it it the `delay` ...?






### How to structure a function

`function` is defined as:
```haskell
instance Function a => Function [a] where
  function f = Map g h (function (\b -> f (h b)))
   where
    g []     = Left ()
    g (x:xs) = Right (x,xs)

    h (Left _)       = []
    h (Right (x,xs)) = x:xs
```

As the definition states, to define `Function [a]`, we should define `Function a`.
In `prop`, `a` is `Char`, and `[a]` is `String`.
*** definition of `function` for `Char` is ...?
*** The intermediary type is `Integer` for `Function Char`.

`function` for `Char` is implemented as
```haskell
instance Function Char where
  function f = Map ord chr (function (\b -> f (chr b)))
```
*** explain this...?
We call `function` with a function that takes an `Int` (its Int or Integer) value:
```haskell
instance Function Int where
  function f = Map fromIntegral fromIntegral (function (\b -> f (fromIntegral b)))
```

`Map` constructor takes two function and an instance of `:->` data type.
It returns an instance of `[a] :-> b` in this case.
The two functions are created inside `function`.
The third argument is passing a manullay-created function to `function` itself.
This argument type is `Either () (a, [a]) :-> b` in this case.

`function` picks an intermediary type, for example `Either () (a, [a])` here.
It creates two functions `g` and `h`, one from the input type to this intermediary type,
One from the intermediary type to the return type.
It returns an instance of `:->` created using `Map` type constructor.

The third argument to `Map` is the outcome of calling
`function` for the type `Function (Either () (a, [a]))`:

`function` is defined as:
```haskell
instance (Function a, Function b) => Function (Either a b) where
  function f = function (f . Left) :+: function (f . Right)
```

`function` uses `:+:` type constructor to create an instance of `Either a b :-> c`.
This type constructor needs two instances of `:->` that have the same second type argument.
`a` is `()`, `b` is `(a, [a])`, and `c` is the return type of the original function.

In our example `prop`:
The type of `f . Left` is `() -> Integer`.
The type of `f . Right` is `(Char, String) -> Integer`.
The type of `function (f . Left)` is `() :-> Integer`.
The type of `function (f . Right)` is `(Char, String) :-> Integer`.

The definition expects `Function` to be instanciated for `()` and for `(a, [a])`.

`Function ()` is implemented as:
```haskell
instance Function () where
  function f = Unit (f ())
```

`Function (a, [a])` is implemented as:
```haskell
instance (Function a, Function b) => Function (a,b) where
  function f = Pair (fmap function (function (curry f)))
```

`Pair` takes one function of type `a :-> (b :-> c)`.
In `prop`, `a` is `Char`, `b` is `String`, and `c` is `Integer`.
`f` is `(Char, [String]) -> Integer`.
`f` is `(f . Right)`, the second argument we pass to `:+:` to create implement `Function`
for the `Either` type.

First, we call `curry` on `f` and get:
```haskell
curry f :: Char -> String -> Integer
```

```chatgpt
The curry function takes a function that accepts a tuple as
an argument and transforms it into a function that takes multiple
arguments curried style. It splits the tuple into individual arguments.
```

Then, we call `function` and get:
```haskell
function (curry f) :: Char :-> (String -> Integer)
```
`function` definition we call here is the implementation of `Function` for the type `Char`.

Then, we call `fmap` wiht `function` and the previous result.

So the type of `fmap` is:
```haskell
(String -> Int) -> (String :-> Int)
-> (Char :-> (String -> Int))
-> (Char :-> (String :-> Int))
```

It's implemented as:
```haskell
instance Functor ((:->) a) where
  fmap f (Pair p)    = Pair (fmap (fmap f) p)
  fmap f (p:+:q)     = fmap f p :+: fmap f q
  fmap f (Unit c)    = Unit (f c)
  fmap f Nil         = Nil
  fmap f (Table xys) = Table [ (x,f y) | (x,y) <- xys ]
  fmap f (Map g h p) = Map g h (fmap f p)
```
*** explain this?

Again, this supposes we can call `function` for `String` and for `Char`.

Calling `function` here for `Function String` looks like an intfinite loop.
We call `function` inside its defition.
But, as we have only defition in Haskell, we can never be sure due native
support of lazy-evaluation.
*** what happens ...?

`fmap` for `->` is implemented as:
```haskell
instance Functor ((->) r) where
    fmap f g = \x -> f (g x)
```


The documentation says that `abstract`:
```haskell
-- turns a concrete function into an abstract function (with a default result)
```
`abstract` is:
```haskell
abstract :: (a :-> c) -> c -> (a -> c)
abstract (Pair p)    d (x,y) = abstract (fmap (\q -> abstract q d y) p) d x
abstract (p :+: q)   d exy   = either (abstract p d) (abstract q d) exy
abstract (Unit c)    _ _     = c
abstract Nil         d _     = d
abstract (Table xys) d x     = head ([y | (x',y) <- xys, x == x'] ++ [d])
abstract (Map g _ p) d x     = abstract p d (g x)
```
*** explain this...?
*** do we really need the second argument, `d`, the randomly generated integer?
In the definitions here `d` is the value generated by `d`.
`x` is the value that the property `prop` passes to the generated function.
That is, `x` is `"tiger"`, `"elephant"`, or `"snake"`.
The value generated by `arbitrary :: Gen (Fun String Int)` is a huge
recursive structure. It's created with `Pair`, `Unit`, `:+:`, and `Map`.


As definitions, we have:
```haskell
instance (Function a, CoArbitrary a, Arbitrary b) => Arbitrary (a:->b) where
  arbitrary = function `fmap` arbitrary
  shrink    = shrinkFun shrink -- shrink (returnType -> [returnType])

instance Arbitrary2 (,) where
  liftArbitrary2 = liftM2 (,)
  liftShrink2 shrA shrB (x, y) = [ (x', y) | x' <- shrA x ] ++ [ (x, y') | y' <- shrB y ]

shrink2 :: (Arbitrary2 f, Arbitrary a, Arbitrary b) => f a b -> [f a b]
shrink2 = liftShrink2 shrink shrink

instance (Arbitrary a, Arbitrary b) => Arbitrary (a,b) where
  arbitrary = arbitrary2
  shrink = shrink2
```




### Creating a function generator, Gen (a -> b)
```haskell
instance (CoArbitrary a, Arbitrary b) => Arbitrary (a -> b) where
  arbitrary = promote (\a -> coarbitrary a arbitrary)
```
`Arbitrary1`, the class, is defined as:
```haskell
arbitrary1 :: (Arbitrary1 f, Arbitrary a) => Gen (f a)
arbitrary1 = liftArbitrary arbitrary

class Arbitrary1 f where
  liftArbitrary :: Gen a -> Gen (f a)
```
First we generate a `Gen b`, or `Gen Integer`, then we call `liftArbitrary`
to make a `Gen (f b)`, or `Gen (f Integer)`.
This means the type of `f b` is `(a -> b)` and the type of `f` is `b -> (a -> b)`.
`liftArbitrary` for `f :: b -> (a -> b)` is defined as:
```haskell
instance (CoArbitrary a) => Arbitrary1 ((->) a) where
  liftArbitrary arbB = promote (`coarbitrary` arbB)
```
`a -> b` can be written also as `((->) a) b`.
`liftArbitrary` here takes a `Gen b` instance and returns a `Gen (a -> b)` instance.
The type of `coarbitrary` here is `Gen b -> (((->) a) -> Gen b)`, that is `Gen b -> (a -> Gen b)`.
The type of `promote` is `(a -> Gen b) -> Gen (a -> b)`.
`promote` is defined as:
```haskell
-- | Promotes a monadic generator to a generator of monadic values.
promote :: Monad m => m (Gen a) -> Gen (m a)
promote m = do
  eval <- delay
  return (liftM eval m)
```

Let's take `prop` an example.
To create a function generator, `Gen (String -> Int)`, we call:
```haskell
instance (CoArbitrary String, Arbitrary Int) => Arbitrary (String -> Int) where
  arbitrary = promote (`coarbitrary` (arbitrary :: Gen Int))
```
This can be written otherwise if we want to simplify `coarbitrary` call:
```haskell
  liftArbitrary arbB = promote (\a -> coarbitrary a (arbitrary :: Gen Int))
```
`promote` type is `(((->) String) (Gen Int)) -> (Gen (((->) String) Int))`,
that is `(String -> Gen Int) -> Gen (String -> Int)`.
`(\a -> coarbitrary a (arbitrary :: Gen Int))` returns a function with the type `String -> Gen Int`.

....


`Function (a, [a])` is implemented as:
```haskell
data a :-> c where
  Pair  :: (a :-> (b :-> c)) -> ((a,b) :-> c)

instance (Function a, Function b) => Function (a,b) where
  function = functionPairWith function function
  -- function :: (b->c) -> (b:->c), function :: (a->b->c) -> (a:->(b->c))
  -- function1 :: (String -> Int) -> (String :-> Int)
  -- function2 :: (Char -> String -> Int) -> (Char :-> (String -> Int)), 
  -- function f = Pair (fmap function function (curry f))
  -- or : function f = Pair (fmap function (function (curry f)))
```

----


In the end, `unGen` will give us a function:
```haskell
-- f :: Gen (String -> Int), the result of generating (String -> Int)

instance :: String -> Int
abstract q numberGenerated ==> abstract (fmap (\q -> abstract q numberGenerated xs) p) numberGenerated x
abstract (fmap (\q -> abstract q numberGenerated xs) p) ==> abstract ...
  ==>
Pair (Map ord chr (Map fromIntegral fromIntegral (fmap function (function (\b -> (\s -> f [chr (fromIntegral b):s]))))))
--> 
Pair (Map ord chr (Map fromIntegral fromIntegral (fmap (function . (\q -> abstract q numberGenerated xs)) (function (\b -> (\s -> f [chr (fromIntegral b):s]))))))



\q -> abstract q numberGenerated xs ==> Map ord chr (Map fromIntegral fromIntegral ())

instance (x:xs) = either (f []) (abstract q numberGenerated) (g x)
   where
    g []     = Left ()
    g (x:xs) = Right (x,xs)

    h (Left _)       = []
    h (Right (x,xs)) = x:xs
```

### Samples
If the testing succeeds, a structure is created:
```erlang
#pass{reason = Reason, samples = lists:reverse(Samples),  printers = lists:reverse(Printers), actions = Actions}.
```
*** `samples` are ...?
`NewSamples = add_samples(MoreSamples, Samples)` is called when the checking succeeds.
It adds `MoreSample` to the existing `Samples`.

*** `printers` are ...?
*** `actions` are ...?

If the input fails to pass the property, a structure is created
```erlang
#fail{reason = Reason, bound = lists:reverse(Bound), actions = lists:reverse(Actions)}.
```
*** `actions` are ...?

*** `save_counterexample` is ...?
```erlang
MinTestCase = clean_testcase(MinImmTestCase),
save_counterexample(MinTestCase),
{false, MinTestCase};
```


## Annex (Haskell/Quickcheck)
Keep in mind that `Prop` and `Property` are different.
`forAll` is defined as `forAll :: (Show a, Testable prop) => Gen a -> (a -> prop) -> Property`.
To create a property, we pass a generator and a function whose return type is a `Testable` instance.
Internally, `forAll` uses these input to create a property generator
that generate an input using the first argument, passes it to the second argument,
and generates a result.
We'll talk more about how this is done later.


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


## Annex (PropEr)

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



`fix_shrink` main logic is:
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

It gets an array of generated inputs,
a structure containing the property,
the failure reason,
the number of shrinks already done,
the maximum number of shrinks named,
and the options structure, the one we pass to `quickcheck` in the first place.


This is how `shrink` is called
```erlang
shrink([], ImmTestCase, StrTest, Reason, 0, ShrinksLeft, init, Opts)
```
It takes the argument we pass to the shrinking function,
and a state, here `init`, as a seventh argument.
This state is defined as `proper_shrink:state()`:
```erlang
-type state() :: 'init' | 'done' | {'shrunk',position(),state()} | term().
```
*** Where do we use each value...?


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



```erlang
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
`aggregate_imm_result`is called as `aggregate_imm_result(lists:map(SpawnFun, WorkerArgs), InitialResult)`.
`WorkerArgs` here is `TestsPerWorker`, the number of tests each worker will handle.
It's the result of calling the strategy function.
The first argument is a list of the pids of the spawned workers.

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


`SpawnFun`, with an impure property, is defined as:
```erlang
SpawnFun = fun({Node, {Start, ToPass}}) ->
              spawn_link_migrate(Node, fun() -> perform(Start, ToPass, Test, Opts) end)
          end,
```

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

The number of tests left is passed as `NumTests * 5` when the number of workers is 0.
Elsewhere, it's `NumTests * 15`.
```erlang
When working on parallelizing PropEr initially we used to hit
too easily the default maximum number of tries that PropEr had,
so when running on parallel it has a higher than usual max
number of tries. The number was picked after testing locally
with different values.
```
At the end, it returns either `#pass` structure, `#fail` structure, or an error.


This function takes 6 arguments.
These are the test, the total number of tests, the options, the number of passing tests,
the number of tests left, samples, and printers.
It returns the testing result.
Testing result is either the `ok` atom, or
```erlang
-type imm_result() :: #pass{reason :: 'undefined'} | #fail{} | error().
```
Other than that, `perform` is called recursively, launching a new testing iteration each time.
PropEr calls `run(Test, Opts)` to check the property.
This function returns a `run_result`, which can be either `#pass`, `#fail`, or `error`.


There are 21 overloaded definition of `run`.
Each variant handles a different kind of test,
a property tuple with a different first element.
But, we can see some patterns.

If the first element is `forall`, we have 4 definitions.
One generates an input and checks the property.
And, the other three variants are called during shrinking.

`shrink` is called:
```erlang
shrink(Bound, Test, Reason, Opts) 
```
`shrink` is defined as
```erlang
-spec shrink(imm_testcase(), test(), fail_reason(), opts()) -> {'ok',imm_testcase()} | error().

```
*** `maybe_stop_cover_server` and `maybe_start_cover_server` are ...?
### Global state
*** `setup_test`, `finalize_test` are ...?
It calls `test` function, which clean up the global states,initialize state variables,calls `inner_test`, then clean up the state again.
*** how does the global attributes change over time...?

*** `cook_test` is ...?

### Printers and reporting
*** `clean_testcase` does ...?
*** `?PRINT` macro is ...?
*** `Printers` are ...?
*** what about `printers = MorePrinters` ...?
*** `report_imm_result` is ...?

### Error handling
*** why calling `check_if_early_fail`...?

*** run -> force -> apply_args -> try apply
```erlang
    catch
	error:ErrReason:RawTrace ->
	    case ErrReason =:= function_clause
		 andalso threw_exception(Prop, RawTrace) of
		true ->
		    {error, type_mismatch};
		false ->
		    Trace = clean_stacktrace(RawTrace),
		    create_fail_result(Ctx, {exception,error,ErrReason,Trace})
	    end;
	throw:'$arity_limit' -> error, arity_limit};
	throw:{'$cant_generate',MFAs} -> {error, {cant_generate,MFAs}};
	throw:{'$typeserver',SubReason} -> {error, {typeserver,SubReason}};
	ExcKind:ExcReason:Trace -> create_fail_result(Ctx, {exception,ExcKind,ExcReason,Trace})
```

*** run -> proper_gen:safe_generate
```erlang
	{error,_Reason} = Error ->
	    Error
```

*** perform ->check_if_early_fail()

*** perform -> case run(Test, Opts)
```erlang
#fail{} = FailResult ->
	    Print("!", []),
        R = FailResult#fail{performed = (Passed + 1) div NumWorkers + 1},
        From ! {worker_msg, R, self(), get('$property_id')},
        ok;
    {error, rejected} ->
	    Print("x", []),
	    grow_size(Opts),
	    perform(Passed, ToPass, TriesLeft - 1, Test,
		    Samples, Printers, Opts);
    {error, Reason} = Error when Reason =:= arity_limit
			      orelse Reason =:= non_boolean_result
			      orelse Reason =:= type_mismatch ->
	    From ! {worker_msg, Error, self(), get('$property_id')},
        ok;
	{error, {cant_generate,_MFAs}} = Error ->
	    From ! {worker_msg, Error, self(), get('$property_id')},
        ok;
	{error, {typeserver,_SubReason}} = Error ->
	    From ! {worker_msg, Error, self(), get('$property_id')},
        ok;
	Other ->
        From ! {worker_msg, {error, {unexpected, Other}}, self(), get('$property_id')},
        ok
```

*** get_result -> hrink(Bound, Test, Reason, Opts)
```erlang
	{error,ErrorReason} = Error ->
	    report_error(ErrorReason, Opts#opts.output_fun),
	    {Error, Error}
```

*** shrink -> fix_shrink
```erlang
	{Shrinks,MinImmTestCase} ->
	    case rerun(Test, true, MinImmTestCase) of
		#fail{actions = MinActions} ->
                    report_shrinking(Shrinks, MinImmTestCase, MinActions, Opts),
		    {ok, MinImmTestCase};
		%% The cases below should never occur for deterministic tests.
		%% When they do happen, we have no choice but to silently
		%% skip the fail actions.
		#pass{} ->
                    report_shrinking(Shrinks, MinImmTestCase, [], Opts),
		    {ok, MinImmTestCase};
		{error,_Reason} ->
                    report_shrinking(Shrinks, MinImmTestCase, [], Opts),
		    {ok, MinImmTestCase}
	    end
    catch
	throw:non_boolean_result ->
	    Print("~n", []),
	    {error, non_boolean_result}
```

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
