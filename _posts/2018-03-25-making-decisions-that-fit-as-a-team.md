---
layout: post
comments: true
title:  "Making decisions that fit as a team"
date:   2018-03-25 10:27:24 +0100
categories: Software, design
tags: featured
---

The line between a gut decision and a design decision is very thin. I am more convinced today than ever that almost all what we call design or architectural decisions are gut decisions that fit well within the decision-maker view and experience of the world.

## Software design as decision-making

Software design can be seen as a set of decisions made by the people involved. Decisions are interdependent. So, the scope, the impact, and the time needed to make a decision varies unpredictably. To make a decision, I think about old decisions which have influence over what I am trying to  do now. This is, I think, what makes estimation complex. Narrowing down the decisions that influence the current decision in a continuously changing environment is the hard part of finding a solution, harder it is to find wich decisions to change and how to change those so that a solution fits in.

Making the all constraints explicit before changing a line of code is costly. Having one person make all the decisions at different levels accelerates the development. He has all the decisions in his mind. He thinks implicitly about them before making a decision. They are the same decisions he will be making over and over if he start the project again. They are grounded in the metaphors he sees the world by (see more about this in the surgical team chapter, Mythical Man Month, Fred Brooks).

This assumes the person learns nothing that changes his deeply-held assumptions, and this works far more than I imagine. That does not means that consistency of the view held by the person will not fail, but that challenging the view is a pure communication and political problem. Also, the cost of working around the boundaries might not be that big.

What about distributed decision-making now? Taking different views on decisions helps decision-making due to faster feedback loops. When we distribute decision-making, we tolerate conflict between how different people think about the solution.

“This works. It allows us to ship and get money. But, Joe, this is not how code should be written. Please, spend an extra day and write it exactly like this.”

Heard that before, yeah me too, and that makes me feel bad.

Far far away, the story goes on like this, “A programmer needs to change the code, he needs to make a decision, he makes explicit all the existing decisions involved, he thinks about the priorities of the organization, he makes the constraints explicit, he finds a solution that fits well, he makes a set of decisions, and he writes the code.” Sometimes, old decisions need to change so that the new decisions fits in. That is the premise of iterative development. Old decisions are not bad. They, once, seemed nice and they delivered value.

But in our lands, decisions are made by different people, so “makes all the decisions explicit” might be changed to “finds all the decisions and makes them explicit”. Some collective work to find all the decisions will save some time here (as in mob programming).

The new decisions should fit in well. What I mean by “a decision that fits well”, here, is a decision that aligns the best with the context of the organization here and now, and with regard to its purpose. Most of the time, making money is way high up in the organization priorities than delivering a software with perfect design and well-shaped code. They are related, yes, but some math involving risk should done here.

## How to a make decisions

The important questions for me are:

 * "How do I communicate a decision I made?"
 * "How do I find(and keep up with) the decisions made by others?"
 * "How do I make a decision that fits well?"

### Communicating design decisions

My answer to the first two questions will be “assume them”. Contextual patterns help. I remember Grady Booch in an episode of software engineering radio saying “When I visit a new team, I ask them about the design patterns of the system they are working on.” Contextual, ogranisation-constraints adapted patterns enable decisions’ chunking. Anyone on the team can safely assume many decisions from the pattern name when writing code. This speeds up the “finding related decisions”. Also, asking colleagues for hints before working on a part with new updates I am not aware of saves a lot of time, as does pairing and mobbing.

“You make a list of all the decisions and then you go through them before making a decision. You can even add categories, sub-categories, tags, a search facility, and all the fun stuff”, you tell me.

But then, we will have an least one more decision to consider; “maintaining the list of decisions”. As the list grows, the cost of going through the list will be higher than the cost of remembering the decisions (by building a shared knowledge over time) and exploring the code  before making a decision (through assumption->validation/rejection cycle) to find my way out. We are far better at pattern matching than machines until now.

Also, changing a decision may have a ripple effect. Finding other decisions and changing them will make me do the work twice; once for the code and once for the list. Finally, we have continuous change in company context and business priorities that makes the rational behind already-made decisions obsolete (and that what creates technical debt). It is like you have two codebases, and only one can tell you what will happen in the real world.

### Making design decisions

For the third question now, I like to think of a new metric ;the distance between the shared knowledge(the system patterns and the team-wide held assumptions) and the new decision (the new decision may involve changing an existing decision). The greater this distance is, the greater the number of people that needs to be involved.

One exercise I like here goes like this:

 * Every one writes the dependent old decisions on sticky notes
 * Make the priorities of the organization visible
 * Make the new decision
 * Find a set of metrics that will give feedback about the new decision

I am working on this right now. This post will be enriched and improved as I gain deeper insights into the process. I like to hear what you think about this exercise as well as your stories with distributed decision-making in a team.
