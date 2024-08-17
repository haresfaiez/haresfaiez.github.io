---
layout: post
comments: true
title:  "Code entropy in action, Needleant alpha release"
date:   2024-08-25 16:00:00 +0100
tags: featured
---

Programming is mainly about modeling and simulation.

At a much lower level, it's about messages and information.

We don't see planes and seats when we book flights
because a reservation is a message.
It's information we send to a distant entity.

We don't see friends online. We talk to them using random shapes on a screen.
Our minds might believe we're chatting face-to-face.
The shapes convey, or "encodes" if we're to use a more technical term,
information and trigger interactions.

A good application is an elegant information model.
And an "obvious" UI is all about using hints, triggers, and metaphors that feel "natural".

We don't think at this level in our day-to-day work.
We have established patterns and proven solutions for common problems.

This aspect of computation, the abstract thinking about what information is,
and how best to persist it and transmit it for long distances,
is a major part of the science of information.

"Entropy", although it's an overloaded metric, is a pivotal measure of information.

> In information theory, the entropy of a random variable is the average level
> of "information", "surprise", or "uncertainty" inherent to the variable's possible outcomes.
>
> -- [Entropy (information theory)](https://en.wikipedia.org/wiki/Entropy_(information_theory))

This definition is quite abstract and we can stretch it a bit.
As an attempt to connect "Code as communication medium" and "Entropy as a measurement of information",
I created [NeedleAnt](https://www.npmjs.com/package/needleant) to measure Javascript code entropy.

This package aims to give a relative idea of how much information code snippets convey.

It can help compare alternatives.

It may answer questions such as:

* How much entropy does a commit or a pull add or remove?
* Which alternative of the two possible solutions introduces less entropy?
* Which library has a more simple API?
* How many parameters does an API need, relative to what we need to pass to another API?
* What's the entropy of test code logic, compared to the code itself?

The [source code](https://github.com/haresfaiez/needle-ant) is on Github.

You can try a [sample editor](/needle-ant.html) that uses this package.

## Text as thought

The elephant-in-the-room maybe is "text".
There have been many attempts to code in more visually digestable formats.

None had significant success (aside, maybe, from spreadsheets).

> "As far as we were aware, we simply made up the language as we went along.
> We did not regard language design as a difficult problem, merely a simple
> prelude to the real problem: designing a compiler that could produce efficient programs."
>
> -- [John Backus](https://en.wikipedia.org/wiki/John_Backus)

Code is a medium for communicating thoughts.
A team, or a developer, thinks about a solution or a new rule about how the software
should behave, or how it must be further maintained.
Then, they express their idea in text (what we call code).

More often than enough, the initial reasoning is lost.
We call the code a "legacy", and we start creating our legacy for the next maintainers.

Structured text is at the same time expressive (for us to understand),
cheap (for us to edit), and scalable (we have the tool to manage large amounts of it).

Yet, other than some heuristics, we don't have accurate methods to figure out how
well our code is doing.

We usually collect some metrics then subjectively interpret
them and see whether there's something to do,
or have a couple of additional eyes during code review that shed the light
on an aspect of design we're complicating.

Think: in/out dependencies, cyclomatic complexity, number of lines of files and functions, ...

NeedleAnt goes along these lines as well.
It accepts code as text.

When we define multiple variables in a function, we have a lot to keep in mind.
We might expect the usage of any of these possibilities each time.

## Scope as an alphabet

The state space for a variable is the scope.
And defining new variables extends this scope.

This is a more shallow view of the code that a type-based
or a values-based analysis.

Each expression is a combination of the identifiers available in the scope
and the primitives offered by the programming language.

It's a sentence written with this available alphabet.

Taking this approach to its logical conclusions, the more complicated an expression,
the greater its entropy value.

** Big scope -> more to keep in mind/ less consistency ..?
