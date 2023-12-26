---
layout: post
comments: true
title:  "Making decisions that fit as a team"
date:   2018-03-25 10:27:24 +0100
tags: featured
---

I am convinced nowadays that the line between gut decisions and design decisions is very thin.
It is familiarity with the code which fosters smooth progress.
Most of what we call design decisions are decisions that fit well within the decision-maker's view and experience of the world.
The good thing is we can see these decisions as constraints, in the good sense of the word.
They limit options, and so, they enable higher levels of coherence.

## Software design as decision-making

> "Design quality is not a property of the code.
> It's a joint property of the code and the context in which it exists."
>
> -- @sarahmei

Software design (the activity) can be seen as the making of a set of decisions by a team.
The decisions are interdependent. Due to the iterative nature of software development,
the scope, the impact, and the duration of making a decision varies unpredictably.
Software evolves. The same decision can take more time to implement tomorrow than now.

Before making a decision, I try to think of all the old decisions that influence what I am trying to do now.
This, I think, is what makes estimation complex.
Narrowing down the decisions that influence the current decision in a continuously changing
environment is the complicated step in finding a solution, more complicated it is to find
which decisions to change and how to do that so that a solution fits in.

Making the all constraints explicit before changing a line of code is costly.
Having one person make all the decisions at all levels decreases that cost.
He will be able to hold all the decisions in mind.
Indeed, he thinks implicitly about old ones before making a new decision.
They are the same decisions he will be making over and over if he starts the project again.
They are grounded in how he likes code to be written
(see more about this in the surgical team chapter, Mythical Man Month, Fred Brooks).

What about distributed decision-making? Taking different views into account before making
a decision sets up a fast feedback loop, and helps challenging unfit decisions.

Far away, the story goes on like this,
“A programmer is changing the code, he needs to make a decision,
he makes explicit the existing decisions involved,
he thinks about the priorities of the socio-technical system he belongs to,
he makes the constraints explicit,
he finds a solution that fits well,
he makes a set of decisions,
and he writes the code.”

But in our lands, decisions are made by different people, so “makes all the decisions explicit”
might be changed to “finds all the decisions and makes them explicit”.
Some collaborative work to find all the decisions will save some time here (as in mob
programming).

The new decisions should fit in well. What I mean by “a decision that fits well”, here,
is a decision that aligns the best with the context of the organization here and now, and about its purpose.
In most cases, making money is way higher in the organization's priorities than delivering
software with perfect design and good-looking code.
They are related, of course, but some math involving risk should done.
Also, old decisions need to change, from time to time, so that the new decisions fit in.
This is the premise of iterative development. Old decisions are not bad.
They, once, seemed nice and they delivered value at the time.

The important questions for me are:

 * "How do I communicate a design decision I choose?"
 * "How do I find(and keep up with) the decisions made by others?"
 * "How do I make a decision that fits well?"

## Communicating design decisions

### Patterns

Contextual patterns help.
I remember Grady Booch saying
“When I visit a new team, I ask them about the design patterns of the system they are working
on.”
Contextual, adapted patterns enable decisions chunking.
Anyone can safely assume many decisions by seeing a pattern in the code.
This speeds up the “finding related decisions”.

### Communication

Also, asking colleagues for hints before working on a part with new updates I am not aware of
saves a lot of time, as does pairing and mobbing.

### Decision store?

> “You can make a list of all decisions and you go through them before making a new one.
> You can even add categories, sub-categories, tags, a search function, and all the fun stuff.”

But then, you will have at least one more constraint to consider;
“maintaining the list of decisions”.
As the list grows, the cost of going through the list will be higher than the cost of
remembering the decisions (by building a shared knowledge over time) and exploring the code
before making a new decision (through assumption->validation/rejection cycle).
We are still better than machines at pattern matching.

Then, changing a decision will have a ripple effect.
Finding other decisions and changing them will make us do the work twice;
once for the code and once for the list.

Finally, we have continuous changes in company context and business priorities,
which make the rationale behind already-made decisions obsolete (this is one cause of technical debt by
the way). It is as if you have two codebases, and only one can tell you what will happen in
the real world.

## Making design decisions

For the third question now, I think of a new metric; the gap between the shared knowledge
(the system patterns and the team-wide held assumptions) and the new decision (the new decision
may involve changing an existing decision).
The greater this gap is, the greater the number of people that need to be involved.

One exercise I like doing before making a decision here goes like this:

 * Everyone writes the dependent old decisions on sticky notes
 * Make the priorities of the organization visible
 * Make the new decision
 * Find a set of metrics that will give feedback about the new decision

I am working on this right now.
This post will be enriched and improved as I gain deeper insights into the subject.
I like to hear what you think about this exercise as well as your stories about distributed decision-making in your team.
