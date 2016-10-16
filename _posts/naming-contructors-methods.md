---
layout: post
title:  "Naming construction methods"
date:   2016-10-16 15:42:00 +0100
categories: Software, Naming
tags: featured
---

A construction method hides the instanciation of an object.
It expresses the intent behind the construction; the value
provided by the instance in the context of use.
Indeed, it freezes a subset of arguments while leveraging the setting
of other arguments to the client.

I prefer construction methods with the fewest possible number of arguments.
I like them to be with no arguments at all.
That keeps these methods focused and easier to understand.
It's not unusual that a construction method leads to improvements in the design.

I like naming a construction method after its use.

I use names like: Date.parse(rawData), when the input is a raw representation of the data.
I use it even when the semantic of the data stays unaffected,
but the input and the output types differ.
It is a good name when the type of the rawData is less abstract than the target type.

For a case where the arguments of the construction method are the same as the those
of the constructor, I consider names like: from, of, ...
That communicates a glimpse of symmetry and consistency.
I use methods like: Color.from(red, green, blue), ...

I find, also, that construction methods useful for small fixed sets and boundaries objects.
Consider a null object, for example, or an identity object (in terms of mathematical expressions)
like 0 for addition and 1 for multiplication, or an element of a small and fixed set like dice faces.
I pick names like: Scale.initial(), Range.floor(), Multiplicant.identity(), Face.one(), Face.two(), ...

When I have a constructor with many arguments, but the client needs
to know only about the existence of just some of them,
like when a single argument is relevant to the behaviour exercised by a test case.
I often name the construction method after that argument.
When there are more than one, I consider refactoring to parameter object,
or just name the method after the role of the first argument.
So it goes like: Face.number(four), Invoice.withoutDiscout(identity, date),
User.named(faiez), Birthday.before(today), Event.at(thisEvening), ...
I use these naming heuristics extensively when I create test fixtures.

And you, what do you think about this?
What are your heuristics for naming those methods?
