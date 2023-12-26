---
layout: post
comments: true
title:  "Naming construction methods"
date:   2016-10-16 15:42:00 +0100
categories: Software, Naming
tags: featured
---

A construction method is used to hide the instantiation of a desired object.
It expresses the intent behind the construction, the value
provided by the instance in the context of use.
It does that by fixing a subset of arguments while leveraging the setting
of other arguments to the client.

I use a set of heuristics when I need to use a construction method.

I prefer construction methods with the fewest possible number of arguments.
I like them to have no arguments.
That keeps these methods focused and easier to understand.
It's not unusual that a construction method leads to many improvements in the design.

I like naming a construction method after its use.

I use names like `Date.parse(rawData)` when the input is a raw representation of the data.
I use it even when the semantics of the data stay unaffected,
but the input and output types differ.
It is a good name when the type of the `rawData` is less abstract than the target type.

When the arguments of the construction method are the same as those
of the constructor, I consider names like: `from()`, `of()`, ...
That communicates a glimpse of symmetry and consistency.
I use names like  `Color.from(red, green, blue)`, ...

I find, also, construction methods useful for small fixed sets and boundaries objects.
Consider a null object, for example, or an identity object (in terms of mathematical expressions)
like `0` for addition and `1` for multiplication, or an element of a small and fixed set like dice faces.
I pick names like `Scale.initial()`, `Range.floor()`, `Multiplicant.identity()`, `Face.one()`, `Face.two()`, ...

When I have a constructor with many arguments, but the client needs
to know only about the existence of just some of them,
like when a single argument is relevant to the behaviour exercised by a test case,
I often name the construction method after that argument.
When there is more than one, I consider refactoring to [parameter object](https://refactoring.guru/introduce-parameter-object),
or just naming the method after the role of the first argument.

It goes like `Face.number(four)`, `Invoice.withoutDiscout(identity, date)`,
`User.named(faiez)`, `Birthday.before(today)`, `Event.at(thisEvening)`, ...
I use these naming heuristics extensively when I create test fixtures.

And you, what do you think about this?
What are your heuristics for naming those methods?
