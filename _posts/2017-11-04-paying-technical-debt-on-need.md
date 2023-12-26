---
layout:     post
comments:   true
title:      "Paying technical debt on need"
date:       2017-11-04 14:37:00 +0100
tags:       Software, Design
---

Technical debt is a metaphor coined by Ward Cunningham to outline the need for design
activities that enable a team to keeps delivering value at a sustainable pace.

I think about technical debt as the gap between the shared understanding of the team of
a solution and the knowledge expressed in the design.

When we use 'invoice' to denote a particular financial document,
we associate a financial vocabulary to that concept in the code.
Then, we learn that the clients use 'invoice' to denote other kinds of documents,
non-financial ones.
We need to express that variability in the code; That is a debt.

Let's take another example, a single-page application.
The root view of that application contains a content area.
Each route allows the user to print a sub-view of the application in there.

The implementation of the solution is conceived such that each sub-view is associated to a
javascript file, a style sheet, and an HTML template.
The design is easy to understand and easy-to-change given the early development constraints.

But now, there is duplication between frequently-changed decisions and a lot of implicit
knowledge.
The cost of changing code is increasing.
The solution as the team, now, finds useful to communicate and to reason about
is far from the solution reflected in the code.
There is a debt to pay.

Kent Beck described the problem accurately;

> "An element that solves several problems will only be partly changed.
> This is riskier and more expensive than changing a whole element because first you need
> to figure out what part of the element should be changed and then you need to prove that
> the unchanged part of the element is truly unchanged."
>
> -- [Coupling and Cohesion](https://web.archive.org/web/20090411030053/http://threeriversinstitute.org/blog?p=104)

We need to remove duplication between the sub-views.
In the same time, we need to change the implementation of each view and sub-view
to make important knowledge explicit.

To pay the debt, we improve the situation of the project file-by-file.
We only improve the situation of a file when we need to modify it.

Each time someone touches the code, he/she prepares the subject for change.
In most cases, this means isolating the component(s) in the file.
Then, she puts the change in.
Finally, she improves the code.
The last step involves removing duplication and increasing the symmetries between
similar components.
From time to time, it includes uniting two components.

Paying the debt here is on-need. We design a component just in time.
That is a pull-based approach to pay the debt. We keep delivering value.
In the meantime, we take time to pay the debt.

The component-based design seems like an upfront decision, a projection of the current context
on an uncertain feature.
But, that's what we come near during work, not what we have in mind when we start.
Besides, neither the communication style nor the structure are similar between components.
The variants are consistent and well-documented.
However, the components are not isolated.
That would have cost us a lot.

We used to live with two ways of defining views during the transition and we are maintaining
both in the code.
Also, such modification changes the way a view element is specified and how the routing system
is set up.

We are creating more seams than we proved we needed.
We are establishing a structure that makes the surroundings (routing, caching, ...) assume less so that we change them fluidly.
