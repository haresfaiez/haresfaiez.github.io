---
layout:     post
comments:   true
title:      "Paying technical debt on need"
date:       2017-11-04 14:37:00 +0100
categories: Design
tags:       Software, Design
---

Technical debt is a metaphor coined by Ward Cunningham to outline the need for design
activities that enable a team to keeps delivering value at a sustainable pace.

I think about technical debt as the gap between the shared understanding of the team of
a solution and the knowledge expressed in the design.
When we use 'invoice' to denote a particular financial document,
and we associate a financial vocabulary to that concept in the code.
Then, we learn that the clients use 'invoice' to denote other kinds of documents,
non-financial ones.
We need to express that variability in the code; That is a debt.

Let's take an other example, a single-page application.
The root view of that application contains a content area.
Each route allows the user to print a sub-view of the application in there.

The implementation of the solution is conceived such that each sub-view is associated to a
javascript file, a style sheet, and a HTML template.
The design is easy-to-understand and easy-to-change given the early development constraints.

But now, there is duplication between frequently-changed decisions and a lot of implicit
knowledge.
The cost of changing code is increasing.
The solution as the team, now, finds useful to communicate and to reason about
is far from the solution reflected in the code.
There is a debt to pay.

Kent Beck described the problem accurately;

"An element that solves several problems will only be partly changed.
This is riskier and more expensive than changing a whole element because first you need
to figure out what part of the element should be changed and then you need to prove that
the unchanged part of the element is truly unchanged."
-- [Coupling and Cohesion](https://web.archive.org/web/20090411030053/http://threeriversinstitute.org/blog?p=104)

We need to remove duplication between the sub-views.
And in the same time, we need to change the implementation of each view and sub-view
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

Paying the debt here is on-need. We design a component just-in-time.
That is a pull-based approach to pay the debt. We keep delivering value.
In the mean time, we take time to pay the debt.

The component-based design seems like an upfront decision, a projection of the current context
on an uncertain feature.
But, that is what we come near during work, not what we have in mind when we start.
Besides, nor the communication style, nor the structure are similar between components.
The variants are consistent and well documented, yeah.
But, the components are not totally isolated.
That would have cost us a lot.

We used to live with two ways of defining views during the transition and we are maintaining
both in the code.
Also, such modification changes the way a view element is specified and how the routing system
is set up.

We are creating more seams that we proved we need. 
We are establishing a structure that makes the surrounding (routing, caching, ...) assumes less
so that we change them fluidly.

I would like to hear more stories about dealing with debt.
If you have something in mind, please share it in a comment.
