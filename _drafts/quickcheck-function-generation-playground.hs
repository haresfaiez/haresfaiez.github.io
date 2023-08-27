-- Miscellaneous tests.

{-# LANGUAGE ScopedTypeVariables, TemplateHaskell #-}
import Test.QuickCheck
import Test.QuickCheck.Random
import Test.QuickCheck.Function
import Test.QuickCheck.All
import Test.QuickCheck.Gen
import Test.QuickCheck.Gen.Unsafe

import Control.Monad
  ( liftM
  , liftM2
  )



--prop2 (Fun _ f :: Fun Int Int) (Fun _ g :: Fun Int Int) x = f (g x) == g (f x)
prop2 :: Fun String Int -> Bool
prop2 (Fun _ f :: Fun String Int) = (f "Faiez") == (f "FaiezAgain")


--mfun :: Gen (Int -> String) = promote (\x -> variant x geni)
--mfun (MkGen g) = promote (\x -> MkGen (\r n -> g (integerVariant (toInteger x) $! r) n))
--mastfun mymfun = fmap (functionMap fromIntegral fromInteger) mymfun
--mastfun (MkGen mymfun) = MkGen (\r n -> (functionMapWith function fromIntegral fromInteger) (mymfun r n))
--res :: Gen String -> Gen ((:->) Int String) -> Gen (Fun Int String)
--res (MkGen genS) (MkGen myfn) = MkGen (\r n -> Fun ((myfn r n), (genS r n), NotShrunk) (abstract (myfn r n) (genS r n)))
--main = putStr (((unGen (mfun geni)) seed size) arg)
--generated = abstract (Map cnvInt cnvInt (function (\b -> ((unGen (mfun arbitrary)) seed size) (cnvInt b)))) drand
--generated = \x -> abstract (function (\b -> ((unGen (mfun arbitrary)) seed size) (cnvInt b))) drand (cnvInt x)
--generated = \x -> myabstract (function (\b -> ((unGen (mfun arbitrary)) seed size) (cnvInt b))) drand (cnvInt x)
--generated = \x -> myabstract (function innergenerated) drand (cnvInt x)

geni :: Gen String = arbitrary
cnvInt :: Int -> Int = fromIntegral

mfun :: Gen String -> Gen (Int -> String)
mfun (MkGen g) = do
  eval <- delay
  return (liftM eval (\x -> MkGen (\r n -> g (integerVariant (toInteger x) $! r) n)))

mastfun :: Gen (Int -> String) -> Gen ((:->) Int String)
mastfun (MkGen mymfun) = MkGen (\r n -> Map cnvInt cnvInt (function (\b -> (mymfun r n) (cnvInt b))))

res :: Gen String -> Gen ((:->) Int String) -> (Int -> String)
res (MkGen genS) (MkGen myfn) = abstract (myfn seed size) (genS seed size)

drand = ((unGen arbitrary) seed size)

myabstract :: Show c => ((:->) a c) -> c -> (a -> String)--((:->) a c) -> c -> (a -> c)

myabstract (Pair p)    d (x,y) = "pair1-" ++ myabstract (fmap (\q -> myabstract q d y) p) (show d) x
myabstract (Table xys) d x     = "909:" ++ show d-- head ([y | (x',y) <- xys, x == x'] ++ [d])
myabstract (p :+: q)   d exy   = ":+:1-" ++ either (myabstract p d) (myabstract q d) exy

myabstract (Map g _ (Map g1 h1 p1)) d x     = "map1-" ++ myabstract (Map g1 h1 p1) d (g x)
--myabstract (Map g _ ((Unit p2) :+: (Pair (Table ((q5x,q5y):qoth))))) d x     = "notmap" ++ show p2 ++ "...d=" ++ show d ++ "...x=" --myabstract p d (g x)
myabstract (Map g _ p) d x     = "map2-" ++ myabstract p d (g x)

myabstract (Unit c)    _ r     = "200"
myabstract Nil         d r     = "300"
--myabstract _    d _ = "100"


innergenerated :: Int -> String = (\b -> "Hola:" ++ show (cnvInt b))

generated = myabstract (function innergenerated) drand (cnvInt (cnvInt 55))
--generated = myabstract (function (\b -> innergenerated (hInteger b))) drand (gInteger (cnvInt 55))



seed = mkQCGen 23
size = 9
arg = 49
--main = putStr generated


main = do
  () <- quickCheck (withMaxSuccess 2 prop2)
  return ()
