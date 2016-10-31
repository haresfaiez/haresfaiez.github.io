---
layout: post
title:  "UNIX philosophy: Every program is a filter"
date:   2016-10-31 16:55:43 +0100
categories: Software, unix
tags: featured
---

In our daily life, we interact a lot with technologies.
That pushes us to consume a huge amount of data that springs from different sources and takes various shapes.
We also create data; we pick a name for our new cat, or we share wisdom on the internet.
And from time to time, we even remove data. Data is there to be manipulated.
It provides value because it solves problems.
So, we want the data to be easily grasped, easily propagated, and easily manipulated.

On the other side, our programs rarely create data.
They are not that good at inventing meaningful information on their own.
(They are pretty good at creating bad ones).
All the data manipulated by a program is given by people.
Programs accept data, from one or many providers, 
they manipulate it in the way we tell them to,
and they send the outcome to the destinations we provide.
The output, so, is a transformation of the input.
That transformation could be a function,
so it would be side-effects-free and completely deterministic.

'A program is a filter' used to be a beneficial metaphor for thinking about program design in UNIX systems.
The filter takes the input,
eliminates the undesired properties, and returns it under a new shape.
In the same way that the UNIX command takes the input data, manipulate it,
and returns it in under a new form.

A UNIX command does not ask for an additional input during its execution.
All the configuration should be provided at the beginning,
before the execution starts.
A filter, indeed, does not have side effects.
It has one path associated to each set of options values.

A good UNIX program design tackles the functional knowledge to the heart 
and moves the interaction with the context of execution to the boundaries.
That simplify the work of the program runner, the system, 
which provides three streams to the program:
an input stream, an output stream, and an error stream and let the programs play their game.

The struggle I see with this principle is its ability to scale.
It works well for small programs,
but composing bigger program from a set of filter may introduce a lot of accidental complexities. 
When we put hard decisions on the boundaries on our sub-systems, 
we complicate their relationships between them inside the system. 
The asymmetry previously handled by the program and hidden encapsulated within its boundaries will be pushed to the user.




