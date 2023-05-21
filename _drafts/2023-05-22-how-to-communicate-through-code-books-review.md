---
layout:   post
comments: true
title:    "How to communicate through code: reviews"
date:     2022-05-22 12:02:00 +0100
tags:     featured
---

Can code be readable?: reviews
Can we communicate through code?: reviews
Source code as a communication medium: reviews

Fixing bugs by fighting windmills: reviews
Sixteen years ago, I read "Don Quixote"
He though of windmills as giants and went on to fight.
Sometimes, I think of fixing bugs as conquering a windmill.
we fix behavior, not the concept, not the model, not the thinking that went that went behind the bug.
Code is a model, a part of the truth, but not the whole truth.

I just finished reading reading two books that touch on language and understanding.
Code is made of concepts.
A programmer defines them and puts them into source code, as functions names or as naming conventions.
Other programmer later tries to build models to answer questions about the code.

The questions can be either about the function:
"How is a component HTML built? And why it changes background in here but not there?",
or about the implementation
"Where this event is handler? And what happen wher it's emitted?".
To answer these questions, we should go deep in the code, follow usages, look for names,
and maybe also learning about third-party libraries.
But, in the end, it's about reconstructing the image the progammer encoded.
Sometimes, the author keeps control and can answer these questions.
Other times, it can tell you the rules or the image he was trying to encode.
In most codebases, this image might tell you nothing.
When for example, the author tells that we fire a certain event at a certain time,
it might tell you nothing about why we use it to change the background of another
component.

Two books I read recently might give insights into how we understand the world
and thus how we put the text we read in a source code into a personalized context.
I'll try to reflect on theme in this context.
While writing this, I tried to keep these questions in mind:
  * Can we express our whole view of the solution design in the code?
  * Is a documentation enough? And do we need also a documentation for the documentation?
  * Can structuring the code contribute to understanding?
  * What can we do when expressiveness conflict with reusability, loose coupling, ...?
  * What is the difference between code and text files?
  * Is text the best medium for writing code? Is it the best also for reading it?
  * Why IDE matters?

# Metaphors we live by

# Data and reality

# On the Expressive Power of Programming Languages

# The Cathedral and the Bazaar

