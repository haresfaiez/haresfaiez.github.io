---
layout: post
comments: true
title:  "Making decisions that fit as a team: Discoverability"
date:   2018-06-10 16:33:00 +0100
tags: featured
---

I wrote about collective decision-making in the previous post.
Along the same journey, here, I am giving the subject a closer look.
I am focusing on the activities that precede a decision on how exactly to
change the code.
The goal, of this step, is to build a model of the existing solution
that enables the introduction of the change safely and with a strong guarantee.

## Holistic understanding vs. discoverability

> A system that is not understood in its entirety, or at least to a significant
> degree of detail by a single individual, should probably not be built.
>
> --Niklaus Wirth

So, what does **Niklaus Wirth** mean by "system"? Do I need to understand
how the processor works to a significant degree of detail to write a Prolog program?
I don't think so.
The key, here, is the word "significant"; what is significant? to whom? when? and why?

I understand the saying as an invitation to avoid complexity and a call to build
programs as an aggregation of simple blocks. Again, simple to whom? when? and why?

The answer to the "who?" is "me" (a team member willing to change the code)
and "when?" (now, as I am adding a feature we didn't anticipate).
The "why?" is about old decisions that influence the work I am doing now (I talked about that
in the previous post)

Answering the "what is significant?" depends on what we see as relevant points of view now, many of which are outside the source code.
(storage cost, required time, dependencies..., and especially the state of the system after
the change).

When I write a simple program, I am more likely to keep it all in my head than I do with
a complex program.
Holding a program in my head does not mean being able to recite every state transition in real-time. That is what compilers and machines do.
It means that I can find my way toward reasoning about every particular interaction in the
system from a relevant point of view.
Relevant to how I am changing the solution.
I am confident enough to build a model that allows me to change the code safely.
That confidence in the model comes from the certainty that what is left outside the model won't
be harmed by the change I am making.

We approach the identification of relevant points of view, thus building a model in two ways:

 * Thorough understanding
 * discoverability

We will leave a thorough understanding of the time to deal with, and we will discuss discoverability.

## Optimizing for discoverability

The questions I look forward to answer are:

  * When I need to introduce a feature, will I be able to
     identify, and then reason about the pieces that need to be changed?
     Will a teammate be able to?
  * What changes do I need to make easy for the future?
  * Do I need to do a refactoring or start the next task?
  * Do I need to eliminate duplication? When? What if doing so
    makes reasoning about bigger parts more complex? What if I am sure that I won't be
    touching that code for a long time? What if that exact part is formally verified?

## Refactoring as a support for discoverability

Refactoring for discoverability is a thing.
Refactoring after change is not about projecting our assumptions into the future,
but, about keeping the ability to reason about the code in the future.
And this is, also, why I refactor before changing the code;
to be able to reason about the change I am introducing.
If what I am about to do doesn't help me or help a colleague reason about the next change,
I don't do it.

A significant part of the design is finding which facts to duplicate (and thus introducing coupling)
to keep reasoning about edge cases manageable.
As I see it, programming is a continuous search for edge cases.
Refactoring eliminates most edge cases and to simplify reasoning about
others.

## Abstraction as a support for discoverability

There is no abstraction in a vacuum.
We cannot talk about "an" abstraction, only "a level" of abstraction.
I will come and point to some microservice and shout out "This is a very good abstraction?"
One cannot just hide a bunch of details down there and call it abstraction.

An important benefit of using mathematical abstractions is that
one gets more premises, and thus a whole level or even many levels,
about the code for free. That simplifies discoverability.
Not only do they simplify reasoning, they give you tools and type checkers that help you reason
about the source code.

## Compression as a support for discoverability

It is about writing the least amount of code to communicate an idea.
Refactor to compressed code. More knowledge in less code makes discoverability simple.
