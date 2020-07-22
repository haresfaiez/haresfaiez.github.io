#Purpose
Separate certain actions from casual coding in order to analyse and improve them

#Refactorings
It is the same as refactoring is dynamic typed languages except you also
have a type checker in addition to tests.
The problem is that sometimes the type check passes, but the tests fails.

What you want is that transformations that are wide should be somehow verified by the type system.
Structure changes should be verified by the type system.?
Behavior changes should be small and specific and verified by a test.
In the first, you need to all change the caller and the calee together, no small steps.

Transformations Int -> Int * Int list and Int -> Op Int=> Op Int -> Op Int | Op2 Int list => Op2 Int list -> Int list
seems similar but are not.
There will be surprises along the road and won't probably end up with an Int.
If one such surprise occurs, you won't end up with a hanging list that does nothing and you have to carry it around.

# Transformations that can be validated by a type system
int to singleton sum type: Int -> Opt of Int

## Renaming are relatively easy, because of the type system

## Enrich a sum type invariant
type Cargo = Window | Door
->
type Cargo = Window of matter | Door of size
=> add/replace/delete


## Replace a component is a product type
1. can be done using the previous refactoring
2. create a new type, spread it gradually (by cloning existing functions)
   then remove the old. ==> error prone (copy tests not code?)
3. replace the second element of the product by a sum type
(Int * Int)
->
(Int * list Int)

## Extract type from an existing type
