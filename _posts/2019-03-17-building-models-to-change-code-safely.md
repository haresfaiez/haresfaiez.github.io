---
layout: post
comments: true
title:  "Building models to change code safely"
date:   2019-03-17 07:26:00 +0100
tags: featured
---

![My desk notes]({{site.baseurl}}/res/img/2019-03-16.png)

It has been a while since I became aware of two struggles I have when I write code;
checking incoming dependencies of a block, and checking for the possible outcomes of a function I am using.
In other words, I have difficulty assessing the potential input and output of a block of code.
I am catching myself from time to time and give consideration to each of these.
Nevertheless, I still blow stuff up. One cause for this is false assumptions.
I use thinking shortcuts and mental associations that, when right, save time, and when wrong,
cost time and energy and increases cycle time.

# Assumptions
Let's say I am creating a button. When I click on that button,
I want to read a color code from a remote service and use the result to change the background.

I start by writing a list on my notebook. In this case, it will be:
  * put a button on the page
  * change the background of the button manually
  * use the remote service to set the background for the button
  * use the service on a click on the button

So, what kind of false assumptions I can make as I work through the list?
Here is what I can think of:
  * the service is always up
  * the service is fast the moment of sending the request
  * the service allows me to read the color
  * the service will always give me the color in the encoding I need
  * the text on the button has a different color than the background
  * the click event bubbling does not have unintended side-effects on the parent elements

I might spot a couple of these when I try the example.
But, others require a deep understanding of the system, more control through auxiliary tools.
Some are not detectable in isolation.

When I focus on "changing the color of the button after a click", adjacent concerns
-like the service being down and the click having unintended side-effects on the parent- become secondary.
I might not look at them as blocks of code that need deep consideration.
In other words, the model I build of the solution abstracts away the interaction with the remote
service. I might assume it does not fail because it does not fail as I create the button.
As "real world" examples, think of storing passwords as flat text, granting full cross-origin access,
putting security tokens in the code, ..., you get the idea.

There a distinction between what "may get wrong" and what "may come in the future".
The possibility that the remote service address changes is in the future.
The fact that the service might be down is in the present.

Coupling, you might say. A highly coupled system complicates tasks otherwise simple. I agree.
But, you cannot write a totally decoupled system. Components need to interact to produce results.
Potentially, decoupling modules introduces implicit coupling.
Finally, decoupling has a cost. And, its cost will likely exceed its benefit.

To approach these issues, I try to build a model of the blocks I changing.
The time I take for refining a model probably exceeds the time I spend writing the code.
Not for everything though, it depends on the task.
After a change, either I use the model to validate the change and its impact, or I build a new model
that puts a non-primary concern into focus (the service in the last example).

# Models
I work in small steps. I take the code from one state to the next using the smallest step possible.
Here is how I manage false assumptions.

## Modeling before making a change
I focus on prevention. I find what might go wrong and I account for it in a model.
My team started using example mapping. I found it surprisingly useful to decide how to approach a feature.
When everyone looks for relevant scenarios, from his own point of view, I get a holistic idea about
the constraints. I learn about the model each one has of the system before and after the feature.
And, I make less wrong assumptions.
Baby steps and TDD (T for test or type) check the model in the code.
They, also, help at refining the model. A code which makes a test pass highlights missed conditions.
A test gives me a possibility to model a tiny capability in the code, then think about how it might fail.
I use diagrams, small informal views, and shapes for the model. Or, I just keep notes in the editor or
in my notebook.
Formal verification with TLA+ in my next experiment.

## Modeling while changing the code
I focus on atomic changes; like renaming a local variable, changing the order of lines,
reversing a conditional block, or moving a function.
Before a change, I find what the impact might be and how it might fail.
Then, I prepare the code for change, then change the code.
The change is either manual or automatic.
Finally, I check if the change introduces unintended failure points.
Automated refactoring tools have gone a long way in making those changes safe.
Here, strong static typing supports reasoning more than dynamic typing.

## Modeling after making the change
I focus on inspection. I build a model from the change I made and the impacted areas.
Sometimes, I tend to take a risk in changing things toward a better shape.
Then, I stop and see what I have done (using a `git diff`) and think about what
might fail and what could have been done better.
The important thing for me is keeping the diff manageable.

This is my focus now. There are different approaches to analyzing a diff and building models.
I analyze the change, maybe ask some questions, study it line by line, draw a bird view of a system,
I explore the changed system manually...

> "All problems in computer science are materialized view maintenance."
>
> -- [Neil Conway](https://twitter.com/cmeik/status/1019240930585563136)

A materialized view, indeed, is a model of the knowledge expressed through the code.

I don't do all this for every change. I know that there is a risk sometimes, and I accept that.
Moving to the next thing can be more important.
