---
layout: post
title:  "Refactoring the small block soon"
date:   2016-09-29 22:47:43 +0100
categories: Software, Refactoring
tags: featured
---

This week, I am working on 'The Gilded Rose' refactoring kata proposed by Industrial Logic.
My mission was to make a complex piece of code clear and easier to extend.

I needed to take my first step. But, from where?

My first strategies were holistic.
I started with something like
'Remove all nested conditionals', 'Move accesses to that field to that class'.
In a previous similiar situation,
I started with the decision to 'Replace all arrays with classes' where every entry designare a class.

I was focusing on code smells instead of the knowledge expressed through the code.
I was trying to take away one code smell at a time.
The trouble was that as soon a smell disappears, it comes back, usually under a new form.
Moreover, the code seemed more and more obscure.

So, four or five successive red bars, and I restarted the kata.

I started the second time with a different strategy:
'Take one block, ignore the holisitic view,
refactor that block mercilessly,
then go back and do the same for the next block'.

I did well.
I learned a lot about the solution as I was able to hold less context in my mind.
And, yes, I got it, without that red bar.

This experience recalls some of my first steps with TDD.
There were a voice inside my mind yelling after making a test pass
'Go ahead, write one more test, there will be an interesting pattern that will appear.
Then, you will be able refactor all the mess'.

It turns out that the moment never comes.
It is more that tidy code leads to insights than it is thtat insights that make the code tidy.

There is no a perfect moment or a better situtation for refactoring.
Approaching it through small and safe steps makes it enjoyable and focused.
