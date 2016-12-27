---
layout: post
comments: true
title:  "UNIX philosophy: Every program is a filter"
date:   2016-10-31 16:55:43 +0100
categories: Software, unix
tags: featured
---

We interact with a huge amount of data in our daily lives.
As it is becoming faster and easier to use data,
we can create meaning and solve problems better.
Unix systems assume that all the data needed to solve a problem
is provided, and that the program do not create new raw data.

'A program is a filter' used to be a beneficial metaphor
to think about program design in UNIX systems.
A filter does not have side effects.
It takes an input, eliminates the undesired parts,
and returns the output back.
In the same way, a UNIX command takes the data from the input stream,
transform it or do some computations on it, and returns the result.

The configuration should be specified at the beginning -before the execution starts.
The only allowed side effects are writing and reading from a stream.
They should happen between two atomic operations.
All other side-effects should be programmed in terms of those two primitive operations,
and each operation should limit its interactions with the outside world to
one input at the beginning of the execution and one output operation at the end.
It, indeed, provides a single path for each set of input values.

A good UNIX program design pushes the functional decisions to the heart 
and moves the interaction with the context of execution to the boundaries.
This makes the interaction protocol clear for the designer and eliminates a lot
of coupling between operations.

But, that does not work well for some kind of problems.
The mess otherwise hidden within the boundaries of an operation could be pushed to the user.
Some class of problems where this turns out to be a complicated situation is programs
with intense IO operations and programs where we need a rigourous failure-handling logic.

When we put hard decisions on the the sub-systems, we push the complexty to their relationships. 
