---
layout: post
comments: true
title:  "Taking declarative programming to the next level"
date:   2018-09-15 10:26:00 +0100
tags: featured
---

I like CSS and I see it as a very elegant language.
CSS is declarative, I write what I need and the browser
figures out how to paint it.

Declarative user-interface and component-based architecture are what
one gets when he tries to take the idea behind CSS to the next level.
But, that is it, only the immediate next level.
You need, then, to deal with higher levels on your own way.
Then, you need to handle failures in those
levels in your own way.

A system is declarative to a point.
The point is the browser for CSS,
the SQL query interpreter in a database management system,
and the interpreter in most explicit DSLs.

In frontend development, it is up to the programmer to choose
where to put the point. It might be just above HTML, or may be back
there at the interaction with the persistence system.

## Abstraction level
The more a layer of abstraction depends on layer using it, the
more interconnections, hidden connections in terms of shared knowledge,
it has, and the harder it is to change it.

The more a layer of abstraction depends on layers it uses, the simpler
it will be to understand and to maintain.
The problem is not tight coupling to a framework,
the problem is using the framework for the problem.
And, no, dependency inversion will, at best, take you a bit deeper inside the hole.

Let's examine two, arguably, good abstractions: high-level languages
(compiled languages for new) and the operating system (Linux here).
Opposed to other indirection layers that brings benefit only in specific
contexts (such layered architecture, ORM, ...).

The compiler takes a string (the program) and produces a product
behaving like the string mandates. The input is a specification, a declaration
of the behaviour of the result. The language does not tell the compiler
how to do its job.

You might think that the behaviour of operating system is controlled
through API calls. But, a closer look at the internals of Linux reveals that
most of the behaviour of the operating system is configuration through
data structures which passed at those API calls.
The API are like namespaces, or like the "execute(anyProgram)" function.
And, if we follow the "Replace Parameter with Explicit Methods"
refactoring at the scale of Linux, things will get out of control.
So from there, I concluded that is a local optimization.
It nay work for boolean parameters, but by the time the possible states
of the parameters increases and more sophisticated data structures are required,
the problem of having many functions appears.

## Data structures as a mean to maintainable code
Data structures are declarative, easy to grasp, to create and re-create,
to copy, and , in some languages, to modify.
They are less fragile to change(coming from fixing bugs, adding features,
growing the code to handle edge cases) in the behaviour.

I don't put effort on refactoring small and encapsulated
behaviour that interprets the datastructures.
As rewriting those is faster and easier than understanding them.
One, also, get the benefits of second-rewrite (assuming one can deal
with its downsides).
I don't believe you can understand the code if it is "well-written",
you understand the code through its behaviour maybe or through documentation
or by getting the nitty-gritty of the domain. But, not by reading it.

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
Something which have two important property:

  - Complexity is pushed to the user. UNIX gives the user full freedom, the input
    accepts any string, something which might not be convenient in modern
    applications.

  - A file content is part of the file datastructure which contains its
    owner, permission, location, ...


## State is not the bottleneck
Well, in software design at least.
You need to deal with state. You need to control the view.
And, as you need fine-grained control, you need highly configurable interfaces.

The issues with the state of the program are access and update issues
as "state" is in itself an abstract concept, and thus has many implementations.
The problem arises when concurrent runtime components access shared data.

If you design the state so that no two components access it at the
same time, you no longer have issues.
If you design the access to data well, same thing.

State is another constraint in the design of programs, same as performance,
user experience, and business agility.
One account for in trade-offs before making design decisions.
Duplication of data at the expense of more memory might be fine.
Showing stale data might be fine.
Showing the last update date with data is fine.
Updating old data in real-time might be acceptable.
It, really, depends.

My point here is that making state always at the heart of design may not
be a good idea. Such decision will ripple through the code and you will
find it reflected at all abstraction levels.
Data is highly declarative. So, maybe putting it at the top of the dependency
tree will be more usefiul.
This also why I struggle with the notion of "persistence layer" at the bottom
of the dependency tree.

It is possible to have ambient data access through the application and to design
the application so that no different components access the same shared data at
the same time. You may even design a scenario where this decision is reflected
in the user interface if its cost/benefit ratio there will be better for the business.


So, what do you think? Are datastructures the key toward robust levels of abstractions?
