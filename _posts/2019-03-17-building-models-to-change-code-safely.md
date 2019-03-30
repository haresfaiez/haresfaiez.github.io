---
layout: post
comments: true
title:  "Building models to change code safely"
date:   2019-03-17 07:26:00 +0100
tags: featured
---

![My desk notes]({{site.baseurl}}/res/img/2019-03-16.png)


It has been a while since I became aware of two struggles I usually encounter;
checking the incoming dependencies and the possible outcomes of a function.
As I see it now, what I find hard is finding the possible inputs (not the allowed input) to a
slice of the code.
A well-designed system allows me to control the boundaries of the code exercised by a test.
I test the bits that influence the result without any other part getting in the way.
A well-designed system, I think, should allow me also to reason about the input
and the output of any slice in the code.

Finding the input and output of a part of code depends on the language and the
boundaries of the slice. That is supposed to be easier to do in a strongly typed language.
I remain skeptical in that regard.
Tooling can help me navigate one or two levels. But, then, modules becomes more and
more abstract and the number of possible execution paths became combinatorial.

When I get the input wrong, most of the time it is because I use thinking shortcuts and mental associations
that, when right, save time, and when wrong, cost time and energy and increases cycle time.

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
I work in small steps. I try to manage misleading assumptions by building models of the code
with every step.

## Modeling before making a change
I focus on prevention. I find what might go wrong and I account for it in a model.
Then, I account for the model in the code.

Lately, My team started using example mapping. It is surprisingly useful for deciding how to approach a feature.
When everyone looks for relevant scenarios from his own point of view, others get a better idea about
the constraints.

Baby steps and TDD ("T" here is for both, test and type) check tiny rules of the model in the code.
They help at refining the model when an unexpected constraint emerges.
A test is a way to model a small and concrete capability, then think about how it fails.

I use diagrams, small informal views, and shapes for modeling too.
I use something I call "impact map". It is a mind map of the components affected by the change.
It helps me think more clearly.

I might also keep notes in the editor or in my notebook.
Formal verification with TLA+ in my next experiment.

As I see it, none of the models here need to be consistent. Humans work with inconsistent models,
any consistent models should be in the code.


## Modeling while changing the code
I focus on atomic changes; like renaming a local variable, changing the order of lines,
reversing a conditional block, or moving a function.
Before a change, I find what the impact might be and how it might fail.
Then, I prepare the code for change and introduce my change.
The change can be manual or automatic.
Finally, I check if the change introduces unintended failures.
Automated refactoring tools have gone a long way in making those changes safe.
Here, strong static typing supports reasoning more than weak typing.

## Modeling after making the change
I focus on inspection. I build models from the change I made and the impacted areas.
Each model focuses on an aspect of the solution.


Although the tests pass and the code type-checks, I won't have so much confidence that a program works as expected.
In the same way that the user cannot tell what he needs until he interacts with
the product, a programmer cannot tell whether what he wrote is free of defects until he tries it.
We make rules, and those can easily biased and wrong.
The code is at least one level of abstraction above the end product.
And in that rising of abstraction, bugs emerge.

> "Beware of bugs in the above code; I have only proved it correct, not tried it."
>
> -- Donald Knuth

I stop and see what I have done (using a `git diff`) and think about what
might fail and what could have been done better.
The important thing for me is keeping the diff manageable.

This is my focus now. There are different approaches to analyzing a diff and building models.
I analyze the change, maybe ask some questions, study it line by line, draw a bird view of a system,
I explore the changed system manually...

# So...

> "All problems in computer science are materialized view maintenance."
>
> -- [Neil Conway](https://twitter.com/cmeik/status/1019240930585563136)
