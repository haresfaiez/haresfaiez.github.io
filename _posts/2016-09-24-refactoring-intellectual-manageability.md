---
layout: post
title:  "Refactoring intellectual manageability"
date:   2016-09-24 22:47:43 +0100
categories: Software, Refactoring
tags: featured
---

This week I am working on 'The Gilded Rose' refactoring kata.
It was proposed by Industrial Logic.

The mission was to improve a complex piece of code,
making it more testable and easier to understand and to extend.


-- taking the code through stages, improving whole a little at each stage
-- in other words up-front thiking
My first attempts to approach this task were holistic.
I pick a change, or a single rule that should be applied on the whole piece of code.
Then, I take the code to that destination blindly.
The strategies were like
'Remove all nested conditionals'
or 'Move all accesses to that field to that class'
or 'Replace all arrays with classes'.

What this approach does at best, is to move the problem under a new form.
At worst, it obscures the code more than at the beginning.

So, I started again but with a different strategy.
'Take a single block of code, ignore the holisitic view,
refactor that block mercilessly,
then go ahead and do the same for the next block'.

It feels good.
I learn a lot about the solution as a go and I was able to hold less context in my mind.
Each time I have only to look two steps forward[0].
Just to Isolate the next block from the complex code. Then, make it clean.

There is no a perfect moment for refactoring. There is no even a better situation.
There is only 'yes' and 'now'.
Sometimes in TDD, there will be always a voice inside the mind telling us
"go ahead and write more tests because there is a pattern that will appear soon. Then I will refactor all that mess away".
Never trust it, there is no patterns, focus on making the context of thinking small.
And refactor as soon a possibility appears.
That will decrease the mistake-rate.

Programming invovles design and design is learning and discovery.
Approaching it through small and safe steps makes it more enjoyable, less frustrying and more focused.
It al about the same, clean code is best achieved through small, and focusing step, focusing on each step on a small context,
and maybe two feets around it to avoid any neaby dangers.

If you ?precieve, overlook? a certain danger more than two feets away, don't focus on it. If you need to be there, and it still there, then it will be two feets away and it will be far easier to overcome.

Don't wait for a better situation to refactor. Just put your current understanding into the current situation. It is a journey of learning, not a destination.


[0] That brings to mind the words of Ward Cunningham, the metaphor between software design and sky hiking 'Design is about seeing only two step further'.
