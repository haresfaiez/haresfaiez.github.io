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
When we focus solely on a working implementation and on covering edge cases,
consistency goes out of sight.
Thinking of new behavior, we miss that analogous one already exists,
and that we can leverage it.
Bringing the latter into view leaves usage scenarios and user feedback out.

Cultivating a reflex for stopping regularly and seeking constraints is important.
It's hard to adopt because it's self-confirming not to.
This idea of deliberate looking appears wasteful
in the same way that rewriting code appears a rework.
We think that if there are violated constraints,
we would have considered them in the work done already.
But, it's worth the try.

The last step in TDD's red-green-refactor is another way of seeing this.
When we stop and think about improving the design and the next test scope,
we are reviewing which constraints we violated and which ones we respected.

Renaming is one of the trickiest refactoring because it's hard to foresee.
When we name something, we have a mental image of what to communicate.
Later, we go back and think about the same logic in another thought process,
and the name appears strange.

We work in multi-functional teams.
People have different priorities and, from time to time, foreign points of view.
We don't have physics. We create our vocabulary and our own rules.
If we don't keep them in check. We'll keep inventing new ones.
The interactions surface constraints.
So, when you think the code is ready or when you think the design is done,
stop and look for the constraints or invite someone to take a look.
