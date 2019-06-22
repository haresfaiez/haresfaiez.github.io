---
layout: post
comments: true
title:  "Building models to change code safely"
date:   2019-03-17 07:26:00 +0100
tags: featured
---

At a high level, all problems have easy solutions;
Need some data from a third-party vendor? Well, You just call the service that gives it to you.
Need to change the color of the login button? You just look for the CSS and change it.
You need to handle more users? You replicate the running application.
What is hard is getting the solution to work in context, under the constraints implied by the existing system.
I tend to oversimplify the situations I deal with. And doing that, I miss constraints.
That results in bugs, incomprehensible design, duplication, and bad user experience.

Let's talk about bugs.
As I see the problem now, there are two issues to missing constraints.
Specifying the input, and deciding where and how to interpret the input.
By input here, I don't mean just the data that comes from the user or a database.
I use it in a broader sense; failure of service and its latency are input.

The second issue is more of a design problem.
Having a simple view of the data flow inside the system helps me think clearly,
as I can easily decompose the system and think about each brick independently.
A well-designed system allows me to reason about the input and the output between any two points.
I choose the points, I find the minimal transformations of input data between them.
I change that, then I reflect my change back to the code.

The first issue is more of a failure of building the right mental model of the interacting parts.
I miss potential input mostly because I use thinking shortcuts and mental associations.
That is it, because of inaccurate assumptions I make about the behavior of the system and its neighbors.
And it is what I focus on here; how to build mental models to change the code without introducing bugs.

## Assumptions
Let's say I am creating a button. Then, I fetch a color code from a remote service and use it
as a background each time I click on that button.

I start by nailing down what should be done before starting. In this case, that will probably be:
  * put a button on the page
  * change the background manually
  * use the remote service to set the background
  * use the service when I click on the button

So, what kind of false assumptions I might make (or input I may miss) as I work through the list?

Here is what I can think of:
  * the service is always up
  * the service is fast the moment of sending the request
  * the service permits me to read the color
  * the service gives me the color in the encoding I need when the source of the request is different
  * the service will not change
  * the text will have a different color than the background after changing the color
  * the click event bubbling does not have unintended side-effects on a parent element

I might spot a couple of these when I try the example.
Others require a deep understanding of the system and the use of auxiliary tools to control the behavior
of adjacent systems.
Some of these cannot be seen in isolation. And unless I run the whole system, I will not run across them.

When I focus on "changing the color of the button after a click", concerns
like the service being down and the click having unintended side-effects on the parent become secondary.
The model I build of the solution abstracts away the interaction with the remote service.
I assume it does not fail because it does not fail as I create the button.
As "real world" examples of this mistake, think of storing passwords as flat text, granting full cross-origin access,
putting security tokens in the code, ..., you get the idea.

To approach these issues, I try to build multiple models for the modules I am changing.
The time I take to refine a model may exceed the time I spend writing the code.
After making a change, I use the models to validate the change and its impact, or I build a new model
that brings a non-primary concern into focus (the service in the last example).
Here is the trick, I don't always account for all the models when I start writing the code.
I, usually, take care of them incrementally. The important is that I keep them in mind when I compare
design tradeoffs.

## Models
I work in small steps and I  manage misleading assumptions by building models at each step.

### Modeling before making a change
I focus on prevention. I find what might go wrong and I account for it in a model.

I use diagrams, small informal views, shapes, and random notes for models.
I create something I call "impact map"; a mind map of the components involved in a change and what
their input/output can be.

Baby steps and TDD check tiny rules of a model in the code.
They help at refining a model in small steps if an unexpected constraint emerges.
A test is a way to model a small and concrete capability, then think about how it fails.

My team is using example mapping recently. It is surprisingly useful for deciding how to approach a feature.
When everyone looks for relevant scenarios from a different point of view, I get a better idea about
the constraints.

Formal verification with TLA+ in my next experiment.

### Modeling while changing the code
This is about atomic changes; like renaming a local variable, changing the order of lines,
reversing a conditional block, or moving a function.

I find the impact and how the change allows more input to be accepted by each involved block.
I prepare the code for change. Then, I make the change.

Before starting, I make a hypothesis about the shape of the code after the change.
After finishing, I check the result against that hypothesis.

Automated refactoring tools have gone a long way in making those changes safe.

### Modeling after making the change
I focus on inspection. I build models from the change and the impacted areas.
Each model focuses on a different aspect of the solution.

The bonus here is that I have a running code to help me validate the model.
Models are built from generic rules, and those can easily biased and wrong.
The code is at least one level of abstraction above the end product.
And in that rising of abstraction, bugs emerge.

> "Beware of bugs in the above code; I have only proved it correct, not tried it."
>
> -- Donald Knuth

Although the tests pass and the code type-checks, I won't have so much confidence that a program works as expected.
In the same way that the user cannot tell what he needs until he interacts with
the product, a programmer cannot tell whether what he wrote is free of defects until he tries it.

I stop and see what I have done (often using a `git diff`) and think about what
might fail in the new shape and what could have been done better.
The important thing for me is keeping the diff manageable.

This is my focus now. There are different approaches to analyzing a diff and building models.
I analyze the change, maybe ask some questions, study it line by line, draw a bird view, and
I explore the changed system manually.
