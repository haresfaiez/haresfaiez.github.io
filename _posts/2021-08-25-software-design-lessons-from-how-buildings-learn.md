---
layout:   post
comments: true
title:    "Software design lessons from \"How Buildings Learn\""
date:     2021-08-25 08:00:00 +0100
tags:     featured
---

> The campus will be in a good condition
> when it has not only big building projects that are gradually adding to it, but
> also a continuous series of adaptations—small, very small, and tiny, in ever
> larger quantities—so that by the time you get down to the smallest level,
> you’ve got hundreds of things that are getting tuned all the time. A bench
> here, a window here, a tree here, a couple of paving stones here.

I have just finished [How Building Learn](https://www.goodreads.com/book/show/38310.How_Buildings_Learn) by Stewart Brand.
Software practitioners with different backgrounds recommended it.
Although software development is inherently different from buildings construction,
they share some aspects.
The mismatch between plans and reality, the continuous change, and the organic evolution among others,
are common interests.

## Feedback
> Inhabit early, build forever.

Stewart tells the story of the Bundestag (the German Congress) 1992 relocation.
The new building had a sound system installed to eliminate problems of feedback and volume
adjustments.
But, during the first meeting, this system turned itself down to an inaudible whisper as
the sound was reflecting off the surrounding glass that the only feedback-free level
the sound systems' computer could find was a faint murmur.

This is a story among many.
People often repaint a wall with a different color after painting half of it
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

> He insists that architects can’t really visualize how a building will look and feel,
> nor can anyone else—no matter how computer-enhanced they are—and so construction should be a
> prolonged process of cut-and-try. [...] You are watching a developing wholeness.

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

> All the design intelligence gets forced to the earliest part of the
> building process, when everyone knows the least about what is really needed.

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

> The trick is to remodel in such a way as to make later remodeling
> unnecessary or at least easy. Keep furniture mobile. Keep wiring, plumbing,
> and ducts accessible.

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

> A design imperative emerges: An adaptive building has to allow slippage
> between the differently-paced systems of Site, Structure, Skin, Services, Space
> plan, and Stuff. Otherwise the slow systems block the flow of the quick ones,
> and the quick ones tear up the slow ones with their constant change.
> Embedding the systems together may look efficient at first, but over time it is
> the opposite, and destructive as well.

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

> An organic process of growth and repair must create a gradual sequence of
> changes, and these changes must be distributed evenly across every level of
> scale. [In developing a college campus] there must be as much attention to
> the repair of details—rooms, wings of buildings, windows, paths—as to the
> creation of brand new buildings. Only then can an environment stay balanced
> both as a whole, and in its parts, at every moment of its history.
