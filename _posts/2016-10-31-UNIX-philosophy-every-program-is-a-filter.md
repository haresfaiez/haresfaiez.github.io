---
layout: post
title:  "UNIX philosophy: Every program is a filter"
date:   2016-10-31 16:55:43 +0100
categories: Software, unix
tags: featured
---

In our daily life, we interact a lot with technologies.
That pushes us to consume a huge amount of data 
that springs from different sources and that takes various shapes.

We also create a lot of data; we pick a name for our new cat, or we share wisdom on the internet.
And from time to time, we even remove data, although it seems a bit strange,
and hardly guaranteed by the service provider.
Data provides value because it solves problems. It is meant to be manipulated.
So, we want the data to be easily grasped, easily propagated, and easily manipulated.

On the other side, our programs rarely create data.
They are not that good at inventing meaningful information on their own.
(They are pretty good at creating bad ones).
All the data manipulated by a program is provided by people.
Programs accept data, from one or many providers, 
they manipulate it in the way we tell them to,
and they send the outcome to the destinations we select.
The output, so, is a transformation of the input.

That transformation could be a function,
so that it would be side-effects-free and completely deterministic.

'A program is a filter' used to be a beneficial metaphor for thinking about program design in UNIX systems.
The filter takes the input,
eliminates the undesired properties, and returns it under a new shape.
In the same way that a UNIX command takes the input data, manipulates it,
and returns it in under a new form.

A filter does not have side effects.
It provides a single path for each set of input values.
That is why a UNIX command does not ask for an additional input during its execution.
All the configuration should be provided at the beginning, before the execution starts.

A good UNIX program design tackles the functional knowledge to the heart 
and moves the interaction with the context of execution to the boundaries.
That simplifies the responsibilites of the program runner, the system, 
which provides only three streams to the program
(an input stream, an output stream, and an error stream) and let the programs play their symphony.

The struggle I see with this principle is its aptitude to scale.
The mess previously handled by the program and encapsulated within its boundaries will be pushed to the user.
It works well for small programs, 
but composing a large program from a set of filters may introduce a bit of accidental complexities.
Some class of problems where this turns out to be a complicated situation is programs
with intense IO operations and programs where we need a rigourous failure-handling logic.
When we put hard decisions on the the sub-systems, we push the complexty to their relationships. 
