---
layout: post
comments: true
title:  "The thing about TDD"
date:   2017-06-06 21:12:00 +0100
categories: Software, TDD, Design
tags: featured
---

Now I can say that there is a subtle relation between failing and growing.
We grow by destroying our most held beliefs.
In software, that means forgetting about silver bullets
and understanding the principles behind each practice.

Software is the reflection of the knowledge grown through
the process of finding a solution to a problem.
Once the team identifies the exact problem a user have,
it comes up with an initial attempt, often not a good one.
Then, the members iterate until they come up with a good-enough solution.
Nothing, here, guarantees that the solution will not change some aspects of the
problem. It, certainly, will.

Imagine two teams given the same problem to solve.
Would they end up with the same solution?
I doubt that. It would be an interesting experiment to run by the way.
Each team understands the problem in its own way
and each team expresses the problem in different terms
and its home-grown metaphors.
The difference is in the shared knowledge about the solution.
That knowledge is the product of the rules the team codes by
and the constraints it respects while growing the software.
We find the reflection of that language in conversations,
in code, and in documents.
Each software solution has two levels;
the code and the above-the-code.

When programming, we need to revisit the program to express, at each visit,
the next set of decisions and try to share the relations between these
decisions with themselves and with the existing decisions.
The decisions are like:
  * Each opportunity must have a global identity.
  * The identity of the invoice must be the same as the identity of its source.
  * The user provides the source identity.
  * A fund must have an identity, a name, and a target.

There can be no unit called opportunity or fund in the code.
You might call it a destination while talking about the opportunity
and use types such as existing or stale in a context where fund is the main
subject.

Now, how can we express a new knowledge about a solution in a safe way?
By safe I mean without messing with the previous work
and reflecting the recent learning.
One way to do that is by stating explicitly each new rule.
Code is an expression medium, but programming languages are limiting.

There is the code with all the old decisions, and there is the new decision.
We decide how the solution will look like after adding the new decision,
then we put in the new decision.

Now, can we express the new decision in our mind
and check for it manually? Yes, of course we can.
The enemy here is the size of software.
I don't like adding the new decisions directly to the old decisions because
I got bitten by bias.
Can we express it through types and laws? Yes, of course.
The enemy here is coupling.
It is, also, challenging to manipulate abstractions without falling for biases
and false symmetries unless the types are highly specific.
There should be a balancing between coupling and the specificity of the type.
Can we express it through tests? Yes, of course, and this what TDD is all about.
The enemy here is, also, coupling.
Tests influence indirectly the code,
but allow for more freedom of expression in the code.

The right solution differs between situations.
The important is the mindset.
To acknowledge that the model is not easy to make explicit is key.
To scope, to implement, to validate,
to spread the learning to the coupled units of the code,
and then to make the knowledge easy to grasp, is a useful process.

I am still studying this process.
So, if you have a story to share, please comment.
