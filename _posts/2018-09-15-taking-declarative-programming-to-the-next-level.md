---
layout: post
comments: true
title:  "Taking declarative programming to the next level"
date:   2018-09-15 10:26:00 +0100
tags: featured
---

I like CSS. I see it as a very elegant language.
CSS is declarative. I write what I want my components to look like.
Then, the browser figures out a way to paint them.
This style of specifying the behaviour of a program is known
as declarative programming in many circles.
The idea could be found in many settings; HTML, component-based
frontend design, SQL, Prolog, and in strictly typed functional
programming languages.

But, communicating with such systems from another system with different
principles is challenging. We, often, refer to frameworks to bridge the gap;
ORM, frontend frameworks, ...
A system is declarative to a point.
It is, usually, up to the programmer to choose where to draw the point.

My hypothesis here is this: we need to draw many small such points instead
of few big ones. Each point is, then, a layer of abstraction.
Then, a layer of abstraction is a point between a declarative system
and a non-declarative system interacting with it and depending on it.

## Abstraction layer
A module has outward and inward dependencies; that is it, towards modules
it uses and towards modules using it.

The more a module depends on modules using it, the harder it is to modify.
Those dependencies are implicit, they manifest as shared knowledge.
The more a module depends on modules it uses, the simpler it will be.
Opposing to what is sold, tight coupling to a framework is not the problem,
using the framework in the current context is.

High-level languages (compiled languages here) and operating systems (Linux here)
are two arguably good abstractions. Time and usage confirm that.
A compiler takes a string (the program) and produces a product
behaving as the string mandates. The input is a specification, a declaration
of the behaviour of the result. The language does not tell the compiler
how to do its job.
You might think that the behaviour of operating system is controlled
through API calls. But, a closer look through the internals of Linux reveals that
most of its behaviour is controlled through data structures which are passed
to the kernel runtime while executing those API calls.
API functions are, then, syntactic sugar over datastructures.

Imagine, now, if we follow the "Replace Parameter with Explicit Methods"
refactoring in Linux API functions. Things, surely, will get out of control.
It nay work for boolean parameters. But, by the time the possible states
of the parameter increase, and more sophisticated data structures are required,
the problem of having many functions will pop up.
Declarative specification is neither a set of function calls, neither a set
of sent messages.

## Data structures as a mean to maintainable code
Datastructures are declarative, easy to grasp, to create and re-create,
to copy, and, in some languages, to modify.
They are less fragile to change (coming from fixing bugs, adding features,
growing the code to handle edge cases) in the behaviour.

I don't put much effort on refactoring small and encapsulated
behaviour that interprets the datastructures.
As rewriting those will be faster and easier than understanding them.
One, also, get the benefits of second-rewrite.
I don't believe one can understand the code if it is "well-written",
one does understand the code through its behaviour, or through documentation,
or by mastering the nitty-gritty of the domain. But, not by reading it.

> "We are much better at doing than at understanding" N. N. Taleb, Antifragile

Software tends to have many interconnections, the more complex one is the mapping
between the visual interface and code that produces it.
I believe that understanding software is more about tactical knowledge than
explicit one.

I will not say that it is impossible.
But, to me, in a system that grows over time, it is quite challenging to
design an abstraction level through a set of functions or messages (unless
the content of the  messages are datastructrues that configure the behaviour).
What is above an abstraction level should be seen as declarative
from within.

An abstraction level should not be universal or general and used
across the whole application.
Enough to model the current solution and to prepare datastructures for other
levels to consume.

You can tell me that everything-is-a-file abstraction of UNIX is indeed a good
abstraction and that the user writes commands not datastructures.
You are right.
But, here the input and the output are both the same datastructure.
Something which have two properties:

  - Complexity is pushed to the user. UNIX gives the user full freedom, the input
    accepts any string, something which might not be convenient in modern
    applications.

  - A file content is part of the file datastructure which contains its
    owner, permission, location, ...


## State is not the bottleneck
Well, in software design at least.
You need to deal with state. You need to control the view and you need to persist data.
Making state always at the heart of design may not be a good idea.
It will harm our principles for creating layers of abstraction.
It is also the main cause for hidden dependencies between modules.
Such decision will ripple through the code and you will find it reflected at all levels.

State is another constraint in the design of programs, like performance,
user experience, and business agility.
One accounts for in trade-offs before making design decisions.
Duplication of data at the expense of more memory might be fine.
Showing stale data might be fine.
Showing the last update date with data is fine.
Updating old data in real-time might be acceptable.
It, really, depends.

The issues with the state of the program comes from accesses and updates to the state
as "state" is in itself an abstract concept, and thus has many implementations.
The problem arises when concurrent runtime components access shared data.
So, if you design the state so that no two components access it at the
same time, you no longer have issues.
If you design the access to data well, no issues as well.


So, what do you think? Are datastructures the key toward robust levels of abstractions?
