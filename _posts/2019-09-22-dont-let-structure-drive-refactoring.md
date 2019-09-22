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

Structure and behavior are frames to think about code. Structure is what the code looks like. It answers
questions like how the code is organized, what vocabulary is used for naming, and which programming language
is used. It encompasses things the end user cannot see directly. Behavior is what the code does.
Structure enables behavior.
We change behavior by changing structure. And, we change structure to accommodate new behavior.


## Design by accident
We can change structure without changing behavior. We call it refactoring.
["Refactor Mercilessly"](http://www.extremeprogramming.org/rules/refactor.html) says that you should
>  Refactor mercilessly to keep the design simple as you go and to avoid needless clutter and complexity.

But, refactoring does not lead naturally to a good design.

One can make almost any code look good with decent tools;
some extractions here, some deduplication there, cool names over the corner, small methods, small files,
small packages, and "Yikes!", ship it.
I don't even need to understand what the code says to do this.
The outcome, meanwhile, is hardly a simple design.

Questions like "How much am I refactoring?", "Am I doing enough?", and "what refactorings I am using the most?"
tell me about the simplicity of my design.
Frequent refactoring of the same spot is a code smell.
I write code for a solution, then I get back to it to fix a bug and I find myself refactoring heavily.
That is a red flag.
The structure is accidental. It does not reflect the behavior.
A small change is not supposed to have a significant impact.

It is easy to lose sight of the bigger picture chasing local perfection.
A structure fit for a scenario (a response to an input) is not a structure fit for the behavior as a whole.
Design after use goes wrong when by "use" we mean "what the current scenario requires",
which is different from "what the behavior as a whole requires".
If we keep one module per task, one module per scenario, or one module per
whatever-changes-together-in-this-scenario, we end up with a complex design that fails to adapt to
new scenarios. It is also hard to change the boundaries in the future.


## Let behavior drive refactoring
To keep the structure stable and simple is a constraint on design.
Changing a complex structure amplify complexity.
"Last responsible moment" and "no design upfront" are not "no thinking now".
Give it a shot before deciding to defer the decision.
The model will change later, but it is better to change an existing theory than to start from nothing.

Ubiquitous language in DDD is a good manifestation of behavior reflected in the structure.
Refactoring to model is what I mean by "let behavior drive refactoring".
You won't end up with the same model you start with, it changes. But, it is stable-enough and accurate.
To reflect behavior in structure, we consider how each new behavior fits in the whole.
Structure growth requires continuous attention.
Good programming is knowing when to stop.

One way to go is to stop and reflect thoroughly after each TDD cycle.
TDD for me is RGRW (red, green, refactor, walk).
Write tests after the code.
They draw a picture of structure after change.
And, invite a friend and work together on the solution.
Pair and mob programming are the ultimate solutions for most problems.
