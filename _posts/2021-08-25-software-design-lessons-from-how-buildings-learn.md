---
layout:   post
comments: true
title:    "Software design lessons from \"How Buildings Learn\""
date:     2021-08-25 08:00:00 +0100
tags:     featured
---

I have just finished [How Building Learn](https://www.goodreads.com/book/show/38310.How_Buildings_Learn) by Stewart Brand.
Software practitioners with different backgrounds recommended it.
Although software development is inherently different from buildings construction,
they share some aspects.
The mismatch between plans and reality, the continuous change, and the organic evolution among others,
are common interests.

## Feedback


People often repaint a wall with a different color after painting half of it,
and move home offices to basements to enjoy some tranquility.

Some of these situations happened because designers delayed feedback until the building is done,
others because inhabitants had erroneous expectations about how their
life will go inside the building.

In software, we need to try things out when they are small
and we need to test them together to validate their interaction early.
That way, we fix problems and correct models before they grow in size and complexity.
Complexity itself grows fast. Every function, conditional, or class is a new concept
to be identified, named, and communicated to the team.
After that, it could change meaning and location over time as the code grows.

The only proof we have that plans, models, and architecture diagrams
work without undesired side-effects is the code we write.
If there is another proof, we will code at its level instead.
We went from cards to assembly language, to high-level languages,
and then to memory-managed systems because every time, someone comes up with
a model that proves the design is good without needing all the work we used to do.

We might be able to see how the software will look like through mockups and prototypes.
But, those won't tell us that there is a delay in search results because the
adapter we built over the UI library does not allow synchronization between
two components with highly specific configurations, or because the UI library
itself misses the feature and we need to implement something that fills the hole
while integrating with the library API.

Those problems might not appear early.
We might see that the library handles synchronization well, that the component
integrates well with the library, we might test each component separately.
But, the moment we try to integrate them fully, some unexpected property
blocks us.

## Rough initial design

Close to fast and continuous feedback is the idea of starting with a rough product
and deferring design decisions.
The book tells stories of houses that are fully livable from the very start of construction.
People start with small rooms and rough primaries or with a mobile home/van,
then grow rooms and facilities as the needs arise.

The book has a chapter titled "function melts form".
Ever tried merging two long-lived branches. The feeling is the same.
The form will deteriorate as we strive to fix the function.

The idea is that if one does not live inside a building early and continuously,
it will end up forcing it to its needs that keep changing.
As the building will likely be optimized for a model not tried
in the real world, it will be expensive to change.
That creates friction and makes life hard for inhabitants.

Finishing plans and models before building -let alone before inhabiting the building-
and burying services inside walls are problems that create life-hindering buildings,
as they complicate maintenance.

In software, we might start with an architecture and impose it on the code.
But, the implementation later reveals insight and invites simple abstraction we can
hardly envision when we have only vague requirements.

We need to start with the mindset that the code will change.
The problem can be somewhat mitigated if we refactor continuously to a simpler
design.
If we make an early decision that A and B are independent and that they
should not communicate directly.
Then, we hold on to that decision even when we find out that
the next features require them to communicate heavily.
We need to change the design. If we don't, most bugs will cascade to both
components and duplications will proliferate.

## Different rates of change
A building can be thought of as a stack of layers,
Site, Structure, Skin, Services, Space plan, and Stuff.
Each level changes at its own pace, and much more interaction
happens between constituents of a level than between constituents
of different levels.

In software design, we might not have the same layering.
But, the idea is to put things that change at the same time together
and to separate things that change at different paces.

Sometimes, as we strive for a simple and clear interface, we bury
layers behind each other for the sake of efficiency. Then, we find it
hard to maintain the inner layer, to change it, or to configure it
with the input of a higher layer.

The book gives the example of services (wires and pipes)
hidden inside the structures (walls).
Then, adding a new feeder is major work.
Most inhabitants are not likely to incur the cost,
which impacts the design of the room and its usage.
Stewart suggests we keep wiring accessible in wire mold on
the walls or in cable troughs hanging from ceilings instead.

If we identify layers, we should be able to maintain each of them without hassle.
We have many practices in software that simplify this:
Dependency injection, Inversion of Control, Closures, ...

## A whole
The book draws on Christofer Alexender's philosophies of owner/builder,
vernacular design language, living buildings, and wholeness.
We studied these concepts in software communities and we have
a significant body of knowledge on them.

One big problem in software is visibility.
The design might get complex over time, but we cannot see it
until we have to change some behaviour.

The wisdom of the ages tells us that every change we make, whether
adding new features, fixing malicious behaviour, or removing
components should have two purposes:
 - immediate function
 - contribution to the whole
 
To keep the design manageable as complexity grows, we need
consistency all the time and at all levels and: among components, inside components,
among functions, and inside functions themselves.

Solving a bug by adding a conditional limits future change.
In most cases, it creates an implicit dependency on a certain input.
It might also break consistency. Why wasn't it natural to have it
from the beginning?

Solving the bug by renaming the function, changing its meaning, then fixing the problem
by adding a new concept or new step in an algorithm, leaves more options for the future
and can keep the whole component consistent.
