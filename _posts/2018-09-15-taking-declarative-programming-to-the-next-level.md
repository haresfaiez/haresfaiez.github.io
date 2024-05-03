---
layout: post
comments: true
title:  "Taking declarative programming to the next level"
date:   2018-09-15 10:26:00 +0100
tags: featured
---

I like CSS. I find it a very elegant language.
CSS is declarative. I specify how components will look like.
The browser figures out how to paint them.
The core idea is called [declarative programming](https://en.wikipedia.org/wiki/Declarative_programming).
It is reflected in many systems; HTML, component-based
frontend architecture, SQL, Prolog, and functional
programming languages.

Communicating with such systems from an outsider (a system with a non-declarative aspect)
is challenging. We, often, refer to libraries and frameworks to
bridge the gap; Think ORM, frontend frameworks, ...
Indeed, a system is declarative to a point.
It is up to the programmer to choose where and how to draw the point.

My hypothesis is this: such a point represents a layer of abstraction.
A layer of abstraction is a point between a declarative system
and a non-declarative system interacting with it and depending on it.

## Abstraction layer

A module has outward and inward dependencies; that is it, towards modules
it uses and from modules using it.

The more a module depends on modules using it, the harder it is to modify.
Those dependencies are implicit, they manifest as shared knowledge.
Keep in mind here that shared knowledge is not code duplication.
These are orthogonal things.
The advantage of an abstraction layer is that it brings in a new level
of meaning where the programmer defines a new language and new meanings for
concepts.

The more a module depends on the modules it uses, the simpler it will be.
Opposing to what is sold, tight coupling to a framework is not the problem,
using the framework in the current context is.

High-level languages (compiled languages particularly) and operating systems (Linux here)
are two arguably good abstractions. Time and usage confirm that.
A compiler depends on the program string.
It takes a string (the program) and produces a product
behaving as the string mandates. The input is a specification, a declaration
of the behaviour of the result. The language does not tell the compiler
how to do its job.

You might think that the behaviour of Linux is controlled
through API calls. But, a closer look at its internals reveals that
most of its behaviour is controlled through data structures. These structures are passed
to the kernel runtime through API calls.
API functions are, then, syntactic sugar over data structures.
A perfect API will be a single function that accepts all kinds of data
structures. But, that is too beautiful to be real.

Imagine if we follow "Replace Parameter with Explicit Methods"
refactoring for Linux API functions. Things will get out of hand.
It may bring expressiveness for functions with boolean parameters.
But, by the time the states of the parameter increase,
and more sophisticated data structures are required,
the problem of having many functions to call pops up.

## Data structures as means to maintainable code

Data structures are declarative, easy to grasp, to create and re-create,
to copy, and, in some languages, to modify.
They are less fragile to change (coming from fixing bugs, adding features,
and growing the code to handle edge cases) in the behaviour.

I don't put much effort into refactoring small and encapsulated
behaviour that interprets data structures.
Rewriting those will, often, be faster and easier.
One, also, gets the benefits of rewrite.
I don't believe one can understand the code if it is "well-written",
one does understand the code through its behaviour, through documentation,
or mastering the nitty-gritty of the domain. But, not by reading it.

Software tends to have many interconnections, the more complex ones are the mappings
between what is shown on the screen and the code that produces it.

I will not say it is impossible.
But, to me, in a system that grows over time, it is quite challenging to
design an abstraction level through a set of functions or messages (unless
the content of the messages is data structures that configure the behaviour).
What is above an abstraction level should be seen as declarative
from within.

An abstraction level should not be universal or general and used
across the whole application.
Enough to model the current solution and to prepare data structures for other
levels to consume is good.
Abstraction is about meaning. The same concept has different meanings
within different levels of abstraction.

## State management is not the bottleneck

I need to deal with the state. I need to control the user interface and persist data.
Making state management at the heart of design might not be that good of an idea.
It does not cooperate well with our principles for creating meaningful layers of abstraction.
It is, also, the main cause of implicit dependencies between modules.
Decisions about the state may ripple all over the code.
They will be reflected at all levels.

State management is another constraint in the design of programs, like performance,
user experience, and business agility.
One accounts for trade-offs before making design decisions.
It might form a distinct level of abstraction or it may be hidden within different levels.
Duplication of data at the expense of more memory might be fine.
Showing stale data might be fine.
Showing the last update date with data is fine.
Updating old data in real time might be acceptable.

The issues with the state of the program come from accesses and updates to the state.
State management in itself is an abstract concept. It has many implementations.
Problems arise when concurrent runtime components share a state.
If I design my system so that no two components access a shared state at the
same time, I will no longer have issues.
