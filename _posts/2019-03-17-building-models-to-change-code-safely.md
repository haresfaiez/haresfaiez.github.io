---
layout: post
comments: true
title:  "Building models to change code safely"
date:   2019-03-17 07:26:00 +0100
tags: featured
---

![My desk notes]({{site.baseurl}}/res/img/2019-03-16.png)
A picture of the notes on my desk last week.

It has been a while since I became aware of two struggles I have as I write code;
checking incoming dependencies of a block I am about to change, and checking for
the possible outcomes of a function I am using.
I think about adding a new item to the list; testing, manual exploratory testing.
I catch myself now from time to time before touching the code and give consideration to each of these.
Nevertheless, I still blow stuff up.

# Assumptions
One cause for such struggles is that I make false assumptions about what I am working on.
I use thinking shortcuts and mental associations that, when right, save time, and when wrong,
cost time and energy and increases cycle time.
I need to be aware and assess the cost of one expectation being erroneous better.

Let's say I am creating a button. When I click on it,
I want to read a color code from a remote service then use it as a background for the button.

I start by writing this list on my notebook before I start:
  * show a button on the screen
  * change the background of the button manually
  * use the remote service to set the background for the button
  * use the service on a click on the button

So, what kind of facts I cannot think of that introduce bugs?
Here is what I can think of:
  * the service is down
  * the service is slow the moment of sending the request
  * the service does not allow me to read the color
  * the parsing of the response returned by the service fails
  * the text on the button has the same color as the background of the button
  * the click event bubbling have unintended side-effects on the button parent elements

Some of these are discovered as I play with the example a bit.
Others need a deep understanding of the system and the use of auxiliary tools.
Others are not detectable in isolation.

When I focus on "changing the color of the button after a click", related concerns
like the service being down and the unintended side-effects of the click become secondary,
not blocks of code that need deep consideration.
In other words, the model I build of the solution at that time abstracts away the interaction with the remote
service and view it as a black box.
I might assume it does not fail because it is not failing while I am creating the button.

This is a simple example. It has a few interacting components. But, it conveys the idea.
As "real world" examples, think about storing passwords as flat text, granting full cross-origin access,
storing security tokens in the code, ..., you get the idea.
Same in these cases, the model built to solve the task at hand abstracts away critical details.

Coupling, you might say. A highly coupled system complicates tasks otherwise simple. I agree.
But, you cannot write a totally decoupled system. Components need to interact to produce results.
If a component does not interact with other components, it is dead code.
Decoupled modules in the code potentially mean implicit coupling too.

There a distinction I want to make between what "may get wrong" and what "may come in the future".
The possibility that the remote address changes is in the future.
The fact that the remote server being down is in the present.

To approach these issues, I try to build small models of the parts I am trying to change.
The time I take for constructing the model is probably more than the time I spend coding.
Not for everything though, it depends on the task.
Finally, I use the model to validate the change and its impact, or I build a new model.
I prefer building a new model to focus on other concerns than the task itself, non-functional concerns
for example.

# Models
I work in small steps. I take the code from one state to another following the smallest possible step.
Here is what I use to deal with false assumptions.

## Modeling before making a change
I focus on prevention. I know what might go wrong and I account for it.
My team started using example mapping in the last weeks and I found it surprisingly useful to decide
how to approach a feature.
When everyone tries to find the scenarios, each from a different point of view, I get a holistic idea about
the constraints. I learn about the model each one has of the system before and after the task.
I make less wrong assumptions that way myself.
Baby steps and TDD (T for test or type) work well.
A test gives me a possibility to model a tiny capability in the code, then think about how it fails.
I use diagrams, small informal views, and shapes. They work well too.
Diagrams, indeed, are non-code models.
Formal verification using TLA+ in my next experiment now.

## Modeling while changing the code
I focus on atomic changes like renaming a local variable, changing the order of a couple of lines,
reversing an if-else block, or moving a function.
Before a change, I find what the impact might be, then prepare the code for change, keep note
of the impacted areas, or change the code manually or automatically.
Then, I validate that the change was what I intended.
Automated refactoring tools have gone a long way in making those changes safe.

## Modeling after making the change
I focus on inspection. I build a model from the change I made.
I tend to take a risk in changing things toward a better shape.
Then, I stop and see what I have done (using a `git diff`) and think about what
might fail and what could have been done better. The important thing here is keeping the diff manageable.

I am experimenting with this lately. There are many approaches to analyzing a diff and building models.
I look at the change for some time, maybe ask some questions, study it line by line,
draw a bird view of a system, ...
I, also, explore it manually.

> "All problems in computer science are materialized view maintenance."
>
> -- [Neil Conway](https://twitter.com/cmeik/status/1019240930585563136)

A materialized view, indeed, is a model of the knowledge expressed through the code.

I skip some steps in some situations. I know that not doing this have a risk, and I accept that.
Moving to the next thing can be more important.
