---
layout:   post
comments: true
title:    "Look for the constraints"
date:     2022-06-13 12:00:00 +0100
tags:     featured
---

> A constraint is anything that prevents the system from achieving its goal.
> [Theory of constraints](https://en.wikipedia.org/wiki/Theory_of_constraints)

Like in chess, we move the pawn taking the bishop out.
But, they, moving the rook, finish the game.
When we focus on a working implementation and on covering edge cases,
the coherence of our design goes out of sight.
Thinking of new behavior, we miss that an analogous one already exists,
and that we can leverage it.
Bringing the latter into view leaves usage scenarios and user feedback out.

As we name something, we have a mental image of what to communicate.
Later, we go back and think about the same logic within another thought process,
and the name appears out of place.
If we stop early and think about the behavior in terms of a wider context,
we might move the new code to an adequate module and use expressive names.

The trick is to be aware of the moment when we make a decision.
Cultivating a habit of stopping regularly and looking for constraints,
of seeing the big picture,
and looking at what we're doing from different points of view,
is important.

The last step in TDD's red-green-refactor is one way to internalize this.
We stop and think about improving the design and about the next test scope.
There, we see the constraints we violated.

The idea of deliberately analyzing constraints appears wasteful
in the same way that rewriting code appears as rework.
But, we don't have physics. We create our vocabulary and our own rules.
If we don't keep them in check, we'll keep inventing new ones.

When you think the code is ready, stop and look for the constraints.
Or better, invite someone to take a look.
People see things from different angles.
