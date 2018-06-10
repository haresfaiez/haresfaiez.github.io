---
layout: post
comments: true
title:  "Making decisions that fit as a team: Discoverability"
date:   2018-06-10 16:33:00 +0100
tags: featured
---

I wrote about collective decision-making in the previous post.
Along the same journey, here, I am giving the subject a closer look.
I am focusing on the activities that precedes deciding how to change the code.
In this step, the goal is to build a model of the existing solution that enable
us to introduce the change safely and with strong guarentee.

## Holistic understanding vs. discoverability

> A system that is not understood in its entirety, or at least to a significant
> degree of detail by a single individual, should probably not be built.
>
> --Niklaus Wirth

So, what does **Niklaus Wirth** meant by "system"? Do I need need to understand
how the processor works to a significant degree of detail in order to write a Prolog program?
I don't think so.
The key, here, is the word "significant"; what is significant? to whom? when? and why?

I understand the saying as an invitation to avoid complexity and a call to build programs
as aggregation of simple blocks. Again, simple to who? when? and why?

When I write a simple program, I am more likely to keep it all in my head than I am for
a complex program.
Holding a program in my head does not mean being able recite every state-transition
of the system in real-time. That is what compilers and machines do.
But, it means that I am able find my way toward reasoning about every particular interaction in the
system from the points of view that are relevant to how I am changing the solution.
I am confident enough to build a model which allow me to change the code safely.
That confidence in the model comes from the certainty that what is left outside the model won't
be harmed from the change we are making.

That is a beginning of the answer for the "who?" (me, a team member that is changing the code)
and "when?" (now, as I am adding a feature we didn't anticipate).
The "why?" is about old decisions which influence the work I am doing now (I talked about that
in the previous post)

Answering the "what is significant?" depends on what we see as relevent points of view
(storage cost, required time, dependencies..., and especially the state of the system after
the change).
We approach the identification of relevant points of view in two ways:

 * Thorough understanding
 * discoverability

We will leave thorough understanding to the time to deal with, and we will discoverability.

## Optimizing for discoverability
The questions, indeed, are:

  - When I need to introduce a feature, will I be able to
     identify, and then to reason about the pieces that need to be changed?
     Will a teammate be able to?
  - What changes do I need to make easy for the future?
  - Do I really need to do a refactoring or start the next task?
  - Do I really need to eliminate duplication? When? What if it doing so
    make reasoning about bigger parts more complex? What if I am sure that I won't be
    touching that code for a long time? What if that exact part is formally verified?

## Refactoring as a support for discoverability
Refactoring for discoverability is a thing.
Refactoring after change is not about projecting our assumptions into the future,
but, about keeping the ability to reason about the code in future.
And this is, also, why I refactor before changing the code;
to be able to reason about the change I am introducing.
If what I am about to do doesn't help me or help a colleague reason about the next change,
I don't do it.

A significant part of design is finding which facts ho duplicate
(and thus introducing coupling) in order to keep reasoning about edge cases manageable.
As I see it, programming is a continuous search for edge cases.
Refactoring is a mean to eliminate most edge cases and to simplify reasoning about
others.

## Abstraction as a support for discoverability
There is no abstraction in vaccum.
We cannot talk about "abstraction" or "an" abstraction, only a level of abstraction.
I cannot come in and point to a microservice and shout out "This is a very good abstraction?"
One cannot just hide a bunch of details down there and call it abstraction.

An important benefit from using mathematical abstractions is that
you get more premises, and thus levels, about the code for free, which simplify discoverability.
Not only they simplify reasoning, they give you tools and type systes to help you reason
about the code.

## Compression as a support for discoverability
Least amount of code. Refactor to compressed code. More knowledge in less code
also makes discoverability simple.




