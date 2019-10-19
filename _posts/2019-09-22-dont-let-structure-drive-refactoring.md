---
layout: post
comments: true
title:  "Don't let structure drive refactoring"
date:   2019-09-22 18:23:00 +0100
tags: featured
---

> There are two kinds of changes — behavior changes and structure changes.
> Always be making one kind of change or the other, but never both at the same time.
>
> --Kent Beck, [SB Changes](https://medium.com/@kentbeck_7670/bs-changes-e574bc396aaa)

Structure and behavior are frames to think about code. Structure describes the units;
functions, files, and modules. Behavior is what the application responds
to user actions.

## Design by accident
To change the behavior. First, we make the change easy. Then,  make the change.
Then, we refactor toward a simple and coherent structure.

But, refactoring does not lead naturally to a good structure.
It is not hard to make complicated code look good;
some extractions here, some deduplication there, cool names, small methods, small files,
small packages, and "Yikes!", ship it. Yet, the structure is still fuzzy and the design is accidental.

Design goes wrong when we miss the context (the behavior of each unit
and the behavior of the aggregation of units).
If we consider only one calling function when refactoring another,
and we forget about other calling functions, the design fails to adapt to new scenarios.
The same for modules, packages, and variables.
The ignored units need additional work to connect with the refactored logic.

When I drive my design far from the behavior, I find myself changing the structure heavily,
even before small changes in behavior.
Questions like "How much am I refactoring?", "Am I doing enough?", and "what refactorings I am using the most?"
tell me about how simple my design is. A small change is not supposed to have a significant impact.


## Let behavior drive refactoring
The mapping between structure and behavior cannot be ideal.
The design should bridge the gap between the two.

Refactoring to model in DDD is the closest thing to what I mean by "let behavior drive refactoring".
Ubiquitous language is a good manifestation of behavior reflected in the structure.

One way to go is to stop and reflect thoroughly after each TDD cycle.
Write tests after the code.
They draw a picture of the structure after a change.
Or, Invite a friend and work together on the solution.
Pair and mob programming are the ultimate solutions for most problems.
