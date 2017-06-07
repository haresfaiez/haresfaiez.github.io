---
layout: post
comments: true
title:  "The thing about TDD"
date:   2017-06-06 21:12:00 +0100
categories: Software, TDD, Design
tags: featured
---

I have been thinking about the relation between types,
tests, and software specification.
I have been thinking about the utility of TDD and the how TDD work
in an environment where algebraic data types and pure functions rule.
I could say that there is a subtle relation between failing and growing.
We grow by destroying our most held beliefs.
In software, that means forgetting about silver bullets
and understanding the principles behind each practice.

Software is the reflection of the knowledge grown through
the process of finding a solution to a problem.
Neither the code is the software, nor is it the set of architectural decisions.
Once a team starts to discover the problem a user have,
it comes up with a serious attempt, often not a good one.
Then, the members iterate on it until they come up with a good-enough solution.
Nothing, here, guarantees that the solution will not change some aspects of the
problem. It, certainly, will.

Imagine two teams given the same problem to solve.
Would they end up with the same solution?
I doubt that (It would be an interesting experiment to run by the way).
Each team understands the problem in different terms
and each team expresses the solution in a collection home-grown metaphors.
The difference is in the shared knowledge about the solution.
That knowledge is the product of the rules the team codes by
and the set of constraints it respects while growing the software.

When programming, we need to revisit the program.
At each visit, we express the knowledge about the next feature
or change existing decisions about after the discovery of an ambiguity or a bug.
We reflect the knowledge through decisions; decisions about how we express
a computation through code and rules about the identity of an entity
in documents and in conversation.
None of these decisions is independent.
Each of them shares relationships within themselves
and with the existing decisions.

The decisions are like:
  * Each opportunity have a global identity.
  * The identity of the contract is the identity of its source.
  * The user provides the source identity.
  * A fund have an identity, a name, and a target.

There could be no unit called "Opportunity" or "Fund" in the code.
You might call it a "destination" when talking about an "opportunity"
and use types such as "Existing" or "Stale" in a context where "Fund"
is the main subject.

Now, how can we express a new knowledge about a solution in a safe way?
By safe I mean without introducing misconceptions in the existing work
and with reflecting the recent learning in the best possible way.
One way to do that is by stating explicitly each
new rule independently of the code, then introducing it to the code.
There is the code with all the old decisions, and there is the new decision.
We decide how the solution will look like after adding the new decision,
that is it, how the code will behave if the decision is in.
Then, we put in the decision.

Now, can we express the new decision in our mind
and check for it manually? Yes, of course we can.
The enemy here is the size of software.
I, personally, don't like adding new decisions directly to
the old decisions because I got, often, bitten by bias.
Can we express it through types and laws? Yes, of course.
The enemy here is coupling.
It is, also, challenging to manipulate abstractions without falling for biases
and false symmetries unless the types are highly specific.
There should be a balancing between coupling and the specificity of the type.
Can we express it through tests? Yes, of course,
and this is what TDD is about.
The enemy here is, also, coupling.

Code with types is easier to refactor than code with tests.
Tools help a lot in the former situation.
Tests influence indirectly the code,
but allow for more freedom of expression in the code.

The right solution differs. The important is the mindset.
To acknowledge that the model is not easy to make explicit is key.
To scope, to implement, to validate,
to spread the knowledge,
and thenm, to make the knowledge easy to grasp, is a useful process.

I am still studying this process.
So, if you have a story to share, please comment.
