---
layout: post
comments: true
title:  "Subtilties to keep in mind when exploring Erlang"
date:   2020-08-24 21:11:00 +0100
tags: featured
---

Erlang is an elegant language. It offers primitives that foster a seamless experience
for developing concurrent, fault-tolerant, and scalable systems.
However, it implements some commonalities differently from other famous languages.

### Period-space after each statement in the shell
Erlang shell does not evaluate an expression without a `. ` at the end,
a period followed by a space.
When they are missing, the shell assumes you are writing a single multi-line expression
and evaluates all the lines together when it receives a period-space.
In a source file however, only the period is required at the end of an expression.

### No boolean type
Instead of booleans, there are `true` and `false` atoms.
Conditionals and predicates handle clauses with these atoms in a special way.
Programmers are encouraged to use them when a function has only two possible results.

### No else block
The syntax of an if block in Erlang is:
```erlang
if
  condition1 -> result1
  condition2 -> result2
  ...
end. 
```
Erlang tries to find a condition that evaluates to `true`, evaluates its body,
and returns the result.

Use a `true` clause as the last clause to act as an else.
```erlang
if
  condition -> result;
  true      -> fallback
end. 
```
Here `fallback` is evaluated and returned when `condition` is `false`.

### "or" and "and" evaluate both operands
In the expression `A or B`, both A and B will be evaluated, even when A is `true`.
Similarly, both operands are evaluated in `A and B` when A is `false`.
Use `andalso` and `orelse` for lazy evaluation.

### You can overload functions
Although Erlang provides type analysis with Dialyzer, it is a dynamic language.
Compiling a file with `true + 9` succeeds.
Compiling the following code meanwhile fails because the compiler cannot find
a function named `a` with no arguments.
```erlang
a(b) -> 0;
start() -> a(). 
```
The arity of a function is an element of its identity.
Because `a(x)` and `a(x, y)` are different functions,
compilation fails and gives a "function start/0 undefined" error.

### [97, 98, 99] is "abc"
Erlang has no string type. A string is represented as an array of characters.
And, a character is represented by its code point.
`$a=:=97` is true (`$a` is the syntax of a character).

When each element of an array of integers is a code point of printable character,
the shell prints the array as a string.

### Uppercase variables, lowercase atoms
Erlang is a functional language. Variables are immutable.
Once you bind a variable to a value, you cannot change it.

Atoms meanwhile have no value.
You cannot assign (or bind) a value to an atom.
Two atoms with the same name are similar.

Variables start with an uppercase letter.
Atoms start with a lowercase letter.

The interplay between variables and atoms shines in pattern matching operations such as:
```
{ author, Name } = { author, "Faiez" }
```

`author` here is an atom. We use it to match the first element of the tuple.
`Name` is a variable. We bind it to the second element of the tuple.

This will fail when the first element of the tuple is not the atom `author`.

### Single quotes for atoms, double quotes for string literals
String literals must be written with double-quotes.
Single quotes are reserved as an optional notation for atoms.

The previous example can be written as:
```
{ author, Name } = { 'author', "Faiez" }
```

Keep in mind that, with single quotes, atoms might start with uppercase letters,
numbers, or special characters.

The following code works well although `Author` is an atom and it starts with an uppercase letter:
```
{ 'Author', Name } = { 'Author', "Faiez" }
```

### Atoms to identify options
Usually, we use associative arrays to create configuration objects.
Think of a JSON object like `{ port: 3000, host: "localhost" }` in Javascript.

Although Erlang has a map type, libraries use arrays of key-value tuples
where the key is an atom that models a configuration entry instead.

The previous JSON object can be written in Erlang as:
`[{ port, 3000 }, { host, "localhost" }]`.

Erlang provides strong support for serializing and deserializing structures due to its
inter-process and inter-host transparency.
You can save atoms, send them over the wire, and load them with no ceremonies.

### Build a reversed array then reverse it, do not build it in order
We have two options to perform a map or a filter operation on an array:
  * Match on the list, separating its head from its tail,
    transform the head (or ignore it in a filter operation),
    call the function recursively on the tail,
    then return an array containing the transformed head followed by the result
    of the recursive call.
    In the end, this returns a reversed array.
  * Use list comprehension notation `[f(A) || A <- ...]`.

The second is highly inefficient for medium and large arrays.
Using the first approach and reversing the result is idiomatic in Erlang.
Array reversal is implemented natively and it is very efficient.

### No `return` keyword
In Erlang, there are no statements. Everything is an expression and everything
returns a value.
In a function that contains a list of expressions, the evaluation result of
the last expression is the return value of the function.
