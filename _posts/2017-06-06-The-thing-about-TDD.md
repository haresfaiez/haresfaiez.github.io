---
layout: post
comments: true
title:  "The thing about TDD"
date:   2017-06-06 21:12:00 +0100
tags: Software, TDD, Design
---

I have been thinking about the relation between types,
tests, and the specification of software.
I was looking for the use cases of TDD.
Especially, how it fits in an environment where algebraic data types
and pure functions rule.

Software is the reflection of the knowledge grown through
the process of finding a solution to a problem.
Once the members of a team start to uncover the problems users have,
they come up with an initial solution, often not a good one.
Then, they iterate on that attempt until they come up with a good enough solution.
Nothing guarantees that the solution will not change aspects of the
problem. It certainly will.

Given two teams faced with the same problem.
Would they end up with the same solution?
I doubt that (It would be an interesting experiment to run by the way).
Each team understands the problem differently
and each expresses the solution in his set of home-grown metaphors.
That local knowledge is the product of the rules the team codes by
and the set of implicit associations in the code and conversations.

The knowledge translates as decisions to the code.
When programming, we iterate.
At each visit, we express the knowledge about the next feature
or we change an existing decision as a result of an insight.
Each of these decisions is interdependent with other decisions.
There is a significant work of design in deciding which decisions
should be explicit, which move to an external configuration,
and which are best to be implicit.

The decisions are like:

  * Each opportunity has a global identity.
  * The identity of the contract is the identity of its source.
  * The user provides the source identity.
  * A fund has an identity, a name, and a target.

See, most of these are code-independent. Software solutions are discovered
away from the keyboard.
There could be no unit called "Opportunity" or "Fund" in the code.
We may refer to a "Fund" as a "destination" when talking about an "opportunity"
and use types such as "Existing" and "Stale" in a context where the fund
is the main concern.
Here, the decision about the existence of a "Fund" is implicit.
The dependencies of the "Fund" are also implicit.
I express these decisions in other mediums such as UML diagrams.

Now, how to express a new decision safely?

By safe I mean without introducing misconceptions to the existing work
and with reflecting the recent learning in the best possible way.
Can we express the new decision in our mind, write it down,
and check the new behavior manually? Yes, of course we can.
The enemy here is the size of the software.
I don't like adding new decisions directly and without a safety net to
the code because I get, often, bitten by bias.

Can we express it using types? Yes, of course.
The enemy here is coupling.
There should be a balance between coupling and the reusability of the type.

Can we express it through tests? Yes, of course, and this is what TDD is about.
TDD does that by stating explicitly each new rule independently of the code,
then introducing it to the code.
We decide how the solution will look after adding the new decision;
and how the code will behave when the decision is in.
Then, we put in the decision.

The right solution differs. The important is the mindset.
To acknowledge that making the model of the solution explicit is not easy,
and sometimes impossible, is a key.
To scope, to implement, to validate, to spread the knowledge,
and then, to make the expression of knowledge easy to grasp,
is a useful process.
