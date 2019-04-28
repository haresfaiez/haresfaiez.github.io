---
layout: post
comments: true
title:  "Building models to change code safely"
date:   2019-03-17 07:26:00 +0100
tags: featured
---

At some high level, all problems have quite obvious solutions;
you just change the color of the button, or you just call the service, or you just decompose into microservices
then put each on a different machine.
What is hard is getting the solution to work in context, and under actual failure modes, while keeping a simple design.

As I see the problem now, specifying the input to a piece of code is the first issue.
The second is figuring out where to interpret the input and how. This is a design problem.
I may handle the input using different modules and functions at different levels.
Or, I may change one function, then maybe I refactor.
But, when I reason about a particular input example, I want its handling to be clear and explicit.
A well-designed system allows me to reason about the input and the output between any two points.
I select the points in the code, and the programming system gives me the paths and the minimal type that expresses
the transformation of data between them. I want to change that, not the code,
and I want my change to be reflected back to the code.

Back to the first issue, I miss potential input mostly because I use thinking shortcuts and mental associations.
That is it, because of assumptions I make about the behavior of the system and its neighbors.
By input here, I don't mean just the data that originates from the user or a database.
I use it in a broader sense, so that the failure of service, not its result, is an input.
The time of getting a response from a remote machine is also an input.

# Assumptions
Let's say I am creating a button. When I click on that button,
I read a color code from a remote service and use it for the background.

I start, usually, by writing an unordered list on my notebook. In this case, it will be:
  * put a button on the page
  * change the background of the button manually
  * use the remote service to set the background for the button
  * use the service on a click on the button

So, what kind of false assumptions I can make (or input I may miss) as I work through the list?

Here is what I can think of:
  * the service is always up
  * the service is fast the moment of sending the request
  * the service allows me to read the color
  * the service will always give me the color in the encoding I need
  * the text on the button has a different color than the background
  * the click event bubbling does not have unintended side-effects on the parent elements

I might spot a couple of these when I try the example.
Others require a deep understanding of the system and the use of auxiliary tools to control the behavior
of adjacent systems.
Some of these are cannot be seen in isolation. Unless I run the whole system, I will not run across them.

When I focus on "changing the color of the button after a click", concerns
like the service being down and the click having unintended side-effects on the parent become secondary.
The model I build of the solution abstracts away the interaction with the remote service.
I assume it does not fail because it does not fail as I create the button.
As "real world" examples of this mistake, think of storing passwords as flat text, granting full cross-origin access,
putting security tokens in the code, ..., you get the idea.

To approach these issues, I try to build models for the modules I am changing.
The time I take to refine a model may exceed the time I spend writing the code.
After making a change, I use the model to validate the change and its impact, or I build a new model
that brings a non-primary concern into focus (the service in the last example).

# Models
I work in small steps and I  manage misleading assumptions by building models at each step.
None of the models needs to be consistent.

## Modeling before making a change
I focus on prevention. I find what might go wrong and I account for it in a model.
Then, I account for the model in the code.

Now, My team is using example mapping. It is surprisingly useful for deciding how to approach a feature.
When everyone looks for relevant scenarios from his point of view, I get a better idea about
the constraints. It is also a way to use input example to ask questions about the code.

Baby steps and TDD check tiny rules of the model in the code.
They help at refining the model when an unexpected constraint emerges.
A test is a way to model a small and concrete capability, then think about how it fails.

I use diagrams, small informal views, and shapes for modeling too, together with random notes.
I use something I call "impact map";a mind map of the components involved in a change.

Formal verification with TLA+ in my next experiment.

## Modeling while changing the code
This is about atomic changes; like renaming a local variable, changing the order of lines,
reversing a conditional block, or moving a function.
I find what the impact might be and look out for how the change allows
more input to be accepted by the involved blocks.
I use the same modeling tools as is the previous step.
Then, I prepare the code for change and make the change.
I make a hypothesis about the shape of the code after the change before starting.
And I check the result against this hypothesis after finishing.
Automated refactoring tools have gone a long way in making those changes.

## Modeling after making the change
I focus on inspection. I build models from the change I made and the impacted areas.
Each model focuses on an aspect of the solution.
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
